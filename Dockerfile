ARG RUBY_VERSION=2.7.5
FROM ruby:$RUBY_VERSION-bullseye AS hyrax-base

ARG DATABASE_DEB_PACKAGE="default-mysql-server"
ARG EXTRA_DEB_PACKAGES="git"

RUN apt-get update && \
  apt-get install -y --no-install-recommends build-essential \
  curl \
  imagemagick \
  libxml2-dev \
  tzdata \
  nodejs \
  yarn \
  zip \default-jre-headless \
  ffmpeg \
  mediainfo \
  perl \
  $DATABASE_DEB_PACKAGE \
  $EXTRA_DEB_PACKAGES && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  mkdir -p /app/fits && \
  cd /app/fits && \
  wget https://github.com/harvard-lts/fits/releases/download/1.6.0/fits-1.6.0.zip -O fits.zip && \
  unzip fits.zip && \
  rm fits.zip tools/mediainfo/linux/libmediainfo.so.0 tools/mediainfo/linux/libzen.so.0 && \
  chmod a+x /app/fits/fits.sh && \
  sed -i 's/\(<tool.*TikaTool.*>\)/<!--\1-->/' /app/fits/xml/fits.xml
ENV PATH="${PATH}:/app/fits"

RUN useradd -m -u 1001 -U -s /bin/bash --home-dir /app app && \
  chown -R app:app /app
USER app

RUN gem update bundler

RUN mkdir -p /app
WORKDIR /app
COPY .env.development /app/.env.production

COPY --chown=1001 ./scripts/*.sh /app/scripts/
ENV RAILS_ROOT="/app"
ENV RAILS_SERVE_STATIC_FILES="1"

ENTRYPOINT ["./scripts/entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-v", "-b", "tcp://0.0.0.0:3000"]

FROM hyrax-base AS hyrax

ARG APP_PATH=.
ARG BUNDLE_WITHOUT=

ONBUILD COPY --chown=1001 $APP_PATH /app
ONBUILD RUN bundle install --jobs "$(nproc)"
ONBUILD RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DATABASE_URL='nulldb://nulldb' bundle exec rake assets:precompile

FROM hyrax-base AS hyrax-worker-base

ENV MALLOC_ARENA_MAX=2

USER root
RUN apt update && \
    apt install -y --no-install-recommends

CMD bundle exec sidekiq

FROM hyrax-worker-base AS hyrax-worker

ARG APP_PATH=.
ARG BUNDLE_WITHOUT=

ONBUILD COPY --chown=1001 $APP_PATH /app
ONBUILD RUN bundle install --jobs "$(nproc)"
ONBUILD RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DATABASE_URL='nulldb:/nulldb' bundle exec rake assets:precompile
