#!/usr/bin/groovy
@Library('github.com/halkeye/jenkins-shared-library@master') _
buildDockerfile('halkeye/language-versions') {
  stage('Install') {
    steps {
      sh("bundle install")
    }
  }

  stage('Static Analysis') {
    steps {
      sh '''
      bundle exec rubocop \
        --require rubocop/formatter/checkstyle_formatter \
        --format RuboCop::Formatter::CheckstyleFormatter \
        -o checkstyle-result.xml || true
      '''
    }
    post {
      always {
        scanForIssues tool: checkStyle(pattern: 'checkstyle-result.xml')
      }
    }
  }

  stage('Test') {
    steps {
      sh("bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml")
    }
    post {
      always {
        junit 'rspec.xml'
      }
    }
  }
}