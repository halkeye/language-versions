FROM ruby:2.6.5
LABEL maintainer="Gavin Mogan <docker@gavinmogan.com>"
ENV APP_ENV production

RUN gem install bundler:2.1.4 && bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle config  set without 'test development' && bundle install

COPY . .

EXPOSE 3000
USER nobody

CMD ["ruby", "app.rb"]
