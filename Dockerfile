FROM ruby:2.4.2-alpine3.6
MAINTAINER quangkhai.le@grabtaxi.com
ENV BUILD_PACKAGES curl-dev ruby-dev build-base git libffi-dev postgresql-dev nodejs yarn bash
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/*
RUN mkdir /usr/app
WORKDIR /usr/app
COPY Gemfile /usr/app/
COPY Gemfile.lock /usr/app/
RUN bundle install

COPY . /usr/app
RUN rake assets:precompile
RUN whenever --update-crontab
CMD rails s
