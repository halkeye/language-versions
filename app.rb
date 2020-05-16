# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'awesome_print'
require 'sinatra'
require 'rest-client'
require 'json'
require 'octokit'
require 'pry'

CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET']
CLIENT_TOKEN = ENV['CLIENT_TOKEN']
RUBY_ENV = ENV['RUBY_ENV'] || 'development'

enable :sessions

def authenticated?
  CLIENT_TOKEN || client.session[:access_token]
end

def client
  @client ||= Octokit::Client.new(access_token: CLIENT_TOKEN || session[:access_token])
end

get '/login' do
  if authenticated?
    redirect('/')
    return
  end
  erb :'login', :locals => {:client_id => CLIENT_ID}
end

get '/' do
  unless authenticated?
    redirect('/login')
    return
  end
  erb :index, :locals => {
    :client_id => CLIENT_ID,
    :organizations => organizations
  }
end

get %r{/(?<type>(repositoryOwner|organization))/(?<repo>[a-zA-Z0-9-_]+)} do
  unless authenticated?
    redirect('/login')
    return
  end
  erb :repos, :locals => {
    :client_id => CLIENT_ID,
    :github_data => repos_versions(params[:type], params[:repo])
  }
end

# Callback URL for Github Authentication. This gets a github oauth token
# for use in acquiring API data. It's a bit manual and could be replaced with 
# https://github.com/atmos/sinatra_auth_github, but it works well for now.
get '/callback' do
  # Get temporary GitHub code...
  session_code = request.env['rack.request.query_hash']['code']

  # ... and POST it back to GitHub
  result = RestClient.post('https://github.com/login/oauth/access_token',
                          {:client_id => CLIENT_ID,
                           :client_secret => CLIENT_SECRET,
                           :code => session_code},
                           :accept => :json)

  # Make the access token available across sessions.
  session[:access_token] = JSON.parse(result)['access_token']

  # As soon as someone authenticates, we kick them to the home page.
  redirect '/'
end

def repos_versions(type, login)
  memoize_disk("repos_versions_#{type}_#{login}") do
    data = {}

    def repos_data(type, login, client, after = nil)
      query = <<-GRAPHQL
      query {
        #{type}(login: #{JSON.generate(login)}) {
          repositories(first:100, after: #{JSON.generate(after)}) {
            pageInfo {
              hasNextPage
              endCursor
            }
            edges {
              node {
                nameWithOwner
                rubyVersion: object(expression: "HEAD:.ruby-version") {
                  ... on Blob {
                    text
                  }
                }
                nodeVersion: object(expression: "HEAD:.node-version") {
                  ... on Blob {
                    text
                  }
                }
              }
            }
          }
        }
      }
      GRAPHQL
    
      response = client.post '/graphql', {
        query: query
      }.to_json
      if response[:errors]
        response[:errors].each do |exception|
          raise Exception.new(exception[:message])
        end
      end
      response[:data][type.to_sym][:repositories]
    end    

    has_next_page = true
    end_cursor = nil

    while has_next_page do
      repos_data = repos_data(type, login, client, end_cursor)
      has_next_page = repos_data[:pageInfo][:hasNextPage]
      end_cursor = repos_data[:pageInfo][:endCursor]
      repos_data[:edges].each do |edge|
        if !edge[:node][:rubyVersion].nil?
          data[edge[:node][:nameWithOwner]] = "Ruby #{edge[:node][:rubyVersion][:text].chomp}"
        elsif !edge[:node][:nodeVersion].nil?
          data[edge[:node][:nameWithOwner]] = "Node #{edge[:node][:nodeVersion][:text].chomp}"
        end
      end
    end
    data
  end
end


def organizations
  memoize_disk('organizations') do
    data = []

    def graphql_query(client, after = nil)
      query = <<-GRAPHQL
      query { 
        viewer { 
          login
          organizations(last: 100, after: %s) {
            pageInfo {
              hasNextPage
              endCursor
            }
            edges {
              node {
                id
                name
                login
                description   
              }
            }
          }
        }
      }
      GRAPHQL
    
      response = client.post '/graphql', {
        query: format(query, JSON.generate(after))
      }.to_json
      if response[:errors]
        response[:errors].each do |exception|
          raise Exception.new(exception[:message])
        end
      end
      response[:data][:viewer]
    end

    has_next_page = true
    end_cursor = nil

    while has_next_page do
      org_data = graphql_query(client, end_cursor)

      if end_cursor.nil?
        data.push({
          type: 'repositoryOwner',
          name: org_data[:login],
          login: org_data[:login]
        })
      end

      has_next_page = org_data[:organizations][:pageInfo][:hasNextPage]
      end_cursor = org_data[:organizations][:pageInfo][:endCursor]

      org_data[:organizations][:edges].each do |edge|
        data.push({
          type: 'organization',
          name: edge[:node][:name],
          login: edge[:node][:login],
          description: edge[:node][:description]
        })
      end
    end
    data
  end
end

def memoize_disk(name, &block)
  filename = "#{name.to_s}.json"
  if RUBY_ENV == 'development'
    if File.exist?(filename)
      File.open(filename,'r') do |f|
        return JSON.load f
      end
    end
  end
  data = yield block
  if RUBY_ENV == 'development'
    File.open(filename, 'w') do |f|
      f.write(data.to_json)
    end
  end
  data
end