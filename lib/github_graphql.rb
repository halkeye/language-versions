# frozen_string_literal: true

GRAPHQL_QUERY_REPO_FILES = <<~GRAPHQL
  query {
    %<type>s(login: %<login>s) {
      repositories(first:100, after: %<after>s) {
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
            toolVersions: object(expression: "HEAD:.tool-versions") {
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

GRAPHQL_QUERY_ORGANIZATIONS = <<~GRAPHQL
  query { 
    viewer { 
      login
      organizations(last: 100, after: %<after>s) {
        pageInfo {
          hasNextPage
          endCursor
        }
        edges {
          node {
            name
            login
            description   
          }
        }
      }
    }
  }
GRAPHQL

# Wrapper class to do graphql queries to github
class GithubGraphql
  def graphql_query(client, query, opts = {})
    response = client.post '/graphql', {
      :query => format(query, opts)
    }.to_json

    return response if response&.errors.nil?

    response[:errors].each { |exception| raise exception&.message }
  end

  def repos_files(client, type, login, after = nil)
    response = graphql_query(
      client,
      GRAPHQL_QUERY_REPO_FILES,
      {
        :after => JSON.generate(after),
        :login => JSON.generate(login),
        :type => type
      }
    )
    response[:data][type.to_sym][:repositories][:edges] =
      response[:data][type.to_sym][:repositories][:edges].select do |edge|
        # throw away any repos that dont have a name for some reason
        next false unless edge[:node][:nameWithOwner]

        # throw away any repos that dont have any tools
        next false unless (
          edge[:node][:rubyVersion] ||
          edge[:node][:nodeVersion] ||
          edge[:node][:toolVersion]
        )

        true
      end

    response[:data][type.to_sym][:repositories]
  end

  def orgs_list(client, after = nil)
    response = graphql_query(
      client,
      GRAPHQL_QUERY_ORGANIZATIONS,
      {
        :after => JSON.generate(after)
      }
    )
    response[:data][:viewer]
  end
end
