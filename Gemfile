# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'json'
gem 'octokit'
gem 'rest-client'
gem 'sinatra'
gem 'sinatra-health-check'

group :test do
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'awesome_print'
  gem 'byebug'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rubocop', :require => false
  gem 'rubocop-checkstyle_formatter', :require => false
end
