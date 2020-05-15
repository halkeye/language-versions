  require 'sinatra'
  require 'sinatra_warden'

  class Application < Sinatra::Base
    register Sinatra::Warden

    get '/admin' do
      authorize!('/login') # require session, redirect to '/login' instead of work
      haml :admin
    end

    get '/dashboard' do
      authorize! # require a session for this action
      "Welcome to the index. It will help you find the information you need"
    end
  end
