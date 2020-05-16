# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra-health-check'
require 'rest-client'
require 'json'
require 'octokit'

require './lib/filtered_common_logger'
require './lib/github_grqphql'

begin
  require 'pry'
  require 'awesome_print'
  Pry.config.print = proc { |output, value| output.puts value.ai }
rescue LoadError => _e # rubocop:disable Lint/SuppressedException
end

CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET']
CLIENT_TOKEN = ENV['CLIENT_TOKEN']
APP_ENV = ENV['APP_ENV'] || 'development'

enable :sessions
set :logging, false
set :bind, '0.0.0.0'
set :port, 3000

use FilteredCommonLogger, ['/healthcheck']

def github_qraphql
  @github_qraphql ||= GithubGraphql.new
end

def healthchecker
  @healthchecker ||= SinatraHealthCheck::Checker.new
end

def authenticated?
  CLIENT_TOKEN || session[:access_token]
end

def client
  @client ||= Octokit::Client.new(
    :access_token => CLIENT_TOKEN || session[:access_token]
  )
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

get '/healthcheck' do
  headers 'content-type' => 'application/json'
  healthchecker.status.to_json
end

get '/login' do
  if authenticated?
    redirect('/')
    return
  end
  erb :login, :locals => {
    :client_id => CLIENT_ID
  }
end

get %r{/(?<type>(repositoryOwner|organization))/(?<repo>[a-zA-Z0-9_-]+)} do
  unless authenticated?
    redirect('/login')
    return
  end
  erb :repos, :locals => {
    :client_id => CLIENT_ID,
    :github_data => repos_versions(params[:type], params[:repo])
  }
end

get '/callback' do
  # Get temporary GitHub code...
  session_code = request.env['rack.request.query_hash']['code']

  # ... and POST it back to GitHub
  result = RestClient.post(
    'https://github.com/login/oauth/access_token',
    {
      :client_id => CLIENT_ID,
      :client_secret => CLIENT_SECRET,
      :code => session_code
    },
    accept => :json
  )

  # Make the access token available across sessions.
  session[:access_token] = JSON.parse(result)['access_token']

  # As soon as someone authenticates, we kick them to the home page.
  redirect '/'
end

def repos_versions(type, login)
  memoize_disk("repos_versions_#{type}_#{login}") do
    data = {}

    has_next_page = true
    end_cursor = nil

    while has_next_page do
      repos_data = github_qraphql.repos_files(client, type, login, end_cursor)
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

    has_next_page = true
    end_cursor = nil

    while has_next_page do
      org_data = github_qraphql.orgs_list(client, end_cursor)

      if end_cursor.nil?
        data.push({
          :type => 'repositoryOwner',
          :name => org_data[:login],
          :login => org_data[:login]
        })
      end

      has_next_page = org_data[:organizations][:pageInfo][:hasNextPage]
      end_cursor = org_data[:organizations][:pageInfo][:endCursor]

      org_data[:organizations][:edges].each do |edge|
        data.push({
          :type => 'organization',
          :name => edge[:node][:name],
          :login => edge[:node][:login],
          :description => edge[:node][:description]
        })
      end
    end
    data
  end
end

def memoize_disk(name, &block)
  filename = "#{name}.json"
  if APP_ENV == 'development'
    if File.exist?(filename)
      File.open(filename, 'r') do |f|
        return JSON.parse(f.read, { :symbolize_names => true })
      end
    end
  end
  data = yield block
  if APP_ENV == 'development'
    File.open(filename, 'w') do |f|
      f.write(data.to_json)
    end
  end
  data
end
