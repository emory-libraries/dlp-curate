#!/bin/sh
set -e

bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

RAILS_ENV=test bundle exec rails db:create
RAILS_ENV=test bundle exec rails db:migrate
RAILS_ENV=test bundle exec rails db:seed
