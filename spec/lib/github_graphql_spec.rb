# frozen_string_literal: true

require 'octokit'
require './lib/github_graphql'

describe GithubGraphql do
  let (:client) { Octokit::Client.new(:access_token => ENV['CLIENT_TOKEN']) }
  let (:graphql) { GithubGraphql.new }

  it 'should return with the logged in user, and orgs it has access to' do
    VCR.use_cassette('github_graphql_orgs') do
      response = graphql.orgs_list(client)

      expect(response[:login]).to eq('halkeye')
      expect(response[:organizations][:pageInfo][:hasNextPage]).to be false
      expect(response[:organizations][:pageInfo][:endCursor]).to be_truthy
      expect(response[:organizations][:edges]).to be_truthy
      expect(response[:organizations][:edges][0][:node][:name]).to be_truthy
      expect(response[:organizations][:edges][0][:node][:login]).to be_truthy
      expect(response[:organizations][:edges][0][:node][:description]).to be_truthy
    end
  end

  it 'should return repos and the associated files' do
    VCR.use_cassette('github_graphql_repo_files') do
      response = graphql.repos_files(client, 'repositoryOwner', 'halkeye')

      expect(response[:pageInfo][:hasNextPage]).to be true
      expect(response[:pageInfo][:endCursor]).to be_truthy

      expect(response[:edges]).to be_truthy
      response[:edges].each do |edge|
        node = edge[:node].to_h
        expect(node[:nameWithOwner]).to be_truthy
        expect(node).to have_key(:rubyVersion)
        expect(node).to have_key(:nodeVersion)
        expect(node).to have_key(:toolVersions)
      end
    end
  end
end
