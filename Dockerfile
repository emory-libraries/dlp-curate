ARG RUBY_VERSION=2.7.5
FROM ruby:$RUBY_VERSION-alpine3.15 AS hyrax-base

ARG DATABASE_APK_PACKAGE="sqlite-dev mariadb-dev"
ARG EXTRA_APK_PACKAGES="git"

RUN apk --no-cache upgrade && \
  apk --no-cache add build-base \
  curl \
  gcompat \
  imagemagick \
  libxml2-dev \
  tzdata \
  nodejs \
  yarn \
  zip \
  $DATABASE_APK_PACKAGE \
  $EXTRA_APK_PACKAGES

RUN addgroup -S --gid 101 app && \
  adduser -S -G app -u 1001 -s /bin/sh -h /app app
USER app

RUN gem update bundler

RUN mkdir -p /app
WORKDIR /app
COPY .env.development /app/.env.production

COPY --chown=1001:101 ./scripts/*.sh /app/scripts/
ENV RAILS_ROOT="/app"
ENV RAILS_SERVE_STATIC_FILES="1"

ENTRYPOINT ["./scripts/entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-v", "-b", "tcp://0.0.0.0:3000"]

FROM hyrax-base AS hyrax

ARG APP_PATH=.
ARG BUNDLE_WITHOUT=

ONBUILD COPY --chown=1001:101 $APP_PATH /app
ONBUILD RUN bundle install --jobs "$(nproc)"
ONBUILD RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DATABASE_URL='nulldb://nulldb' bundle exec rake assets:precompile

FROM hyrax-base AS hyrax-worker-base

ENV MALLOC_ARENA_MAX=2

USER root
RUN apk --no-cache add bash \
  ffmpeg \
  mediainfo \
  openjdk11-jre \
  perl
USER app

CMD bundle exec sidekiq

FROM hyrax-worker-base AS hyrax-worker

ARG APP_PATH=.
ARG BUNDLE_WITHOUT=

ONBUILD COPY --chown=1001:101 $APP_PATH /app
ONBUILD RUN bundle install --jobs "$(nproc)"
ONBUILD RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DATABASE_URL='nulldb:/nulldb' bundle exec rake assets:precompile
