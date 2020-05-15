# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "sinatra"
gem "sinatra_warden"

group :test do
  gem 'faker'
  gem 'rspec'
end

group :test, :development do
  gem 'rubocop', require: false
end
