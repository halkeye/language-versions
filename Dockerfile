FROM ruby:2.6.5
ARG BUILD_DATE="unknown"
ARG GIT_COMMIT_REV="unknown"
ENV GIT_COMMIT_REV=${GIT_COMMIT_REV}
ARG GIT_SCM_URL="unknown"

LABEL \
  org.label-schema.vendor="Gavin Mogan" \
  org.opencontainers.image.vendor="Gavin Mogan" \
  org.label-schema.name="Language Versions" \
  org.opencontainers.image.title="Language Versions" \
  org.label-schema.version="${GIT_COMMIT_REV}" \
  org.opencontainers.image.version="${GIT_COMMIT_REV}" \
  org.label-schema.docker.schema-version="1.0" \
  maintainer="Gavin Mogan <docker@gavinmogan.com>"
  
ENV APP_ENV production

RUN gem install bundler:2.1.4 && bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle config set without 'test development' && bundle install

COPY . .

EXPOSE 3000
USER nobody

CMD ["ruby", "app.rb"]
