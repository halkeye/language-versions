# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'awesome_print'
require 'sinatra'
require 'rest-client'
require 'json'
require 'octokit'

CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET']

enable :sessions

def authenticated?
    session[:access_token]
end

get '/login' do
  erb :'login', :locals => {:client_id => CLIENT_ID}
end

get '/' do
  gh_data = github_data()
  erb :index, :locals => {:client_id => CLIENT_ID, :gh_data => gh_data}
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
  # example result:
  # { 'access_token':'xxasdfasdf234234123dvadsfasdfas',
  #   'token_type':'bearer',
  #   'scope':'user:email'
  # }

  # Make the access token available across sessions.
  session[:access_token] = JSON.parse(result)['access_token']

  # As soon as someone authenticates, we kick them to the home page.
  redirect '/'
end


######################################
# Other Methods
######################################

# Demonstrate examples of how to get Data using Octokit.rb
# Example API data is from this example account: https://github.com/octocat
def github_data
  unless authenticated?
    redirect('/login')
    return
  end
  puts "session: #{session.to_s}"

  client = Octokit::Client.new(access_token: session[:access_token])

  # Create a hash for collecting our example data.
  data = Hash.new

  # Get various types of data using Octokit.rb

  # User Data:
  # User data is available via client.user. As long as you have be granted access
  # to the 'user' scope, you can access any values given in this example API
  # response: http://developer.github.com/v3/users/#response
  data[:login] = client.user.login # => 'octocat'
  data[:email] = client.user.email # => 'octocat@github.com'
  data[:location] = client.user.location # => 'San Francisco'

  query = <<-GRAPHQL
  query {
    viewer {
      login
    }
    rubyVersion: repository(owner: "halkeye", name: "language-versions") {
      object(expression: "master:.ruby-version") {
        ... on Blob {
           text
         }
      }
    }
  }
  GRAPHQL

  #response = client.post '/graphql', { query: query }.to_json
  #ap response

  return data

  # Repository Data:
  # Repository data is available via client.repository (for a specific repo)
  # or client.repositories for the full list of repos. As long as you have been
  # granted access to the 'repo' scope, you can access any values given in this
  # example API response: http://developer.github.com/v3/repos/#response-1
  #
  # Get data from a specific repository, if that repository exists.
  if client.repository?('octocat/Hello-World')
    data[:repo_id] = client.repository('octocat/Hello-World').id
    data[:repo_forks] = client.repository('octocat/Hello-World').forks_count
    data[:repo_stars] = client.repository('octocat/Hello-World').stargazers_count
    data[:repo_watchers] = client.repository('octocat/Hello-World').watchers_count
    data[:repo_full_name] = client.repository('octocat/Hello-World').full_name
    data[:repo_description] = client.repository('octocat/Hello-World').description
    # Note: You can see all repo methods by printing client.repository('octocat/Hello-World').methods
  end

  # Instantiate an array for storing repo names.
  data[:repo_names] = Array.new
  # Loop through all repositories and collect repo names.
  client.repositories.each do |repo|
    data[:repo_names] << repo.name
  end

  return data
end
