#!/usr/bin/groovy
@Library('github.com/halkeye/jenkins-shared-library@master') _
buildDockerfile('halkeye/language-versions', [:]) {
  rubyVersion = readFile('.ruby-version').trim()
  docker.image("ruby:${rubyVersion}").inside {
    try {
    sh '''
      bundle install
      bundle exec rubocop \
        --require rubocop/formatter/checkstyle_formatter \
        --format RuboCop::Formatter::CheckstyleFormatter \
        -o checkstyle-result.xml || true
      bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
    '''
    } finally {
      scanForIssues tool: checkStyle(pattern: 'checkstyle-result.xml')
      junit 'rspec.xml'
    }
  }
}