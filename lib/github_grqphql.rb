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

# Wrapper class to do graphql queries to github
class GithubGraphql
  def graphql_query(client, query, opts = {})
    response = client.post '/graphql', {
      :query => format(query, opts)
    }.to_json

    return response if response&.errors.nil?

    response[:errors].each { |exception| raise exception&.message }
  end

  def repos_files(client, type, login, after)
    response = graphql_query(
      client,
      GRAPHQL_QUERY_REPO_FILES,
      {
        :after => JSON.generate(after),
        :login => JSON.generate(login),
        :type => type
      }
    )
    response[:data][type.to_sym][:repositories]
  end

  def orgs_list(client, after)
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
