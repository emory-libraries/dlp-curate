# frozen_string_literal: true

# Load DSL and set up stages
require "capistrano/setup"
require "cap-ec2/capistrano"
# Include default deployment tasks
require "capistrano/deploy"
# exec `whenever` every time we deploy so that jobs
# are added to crontab
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

# Load the SCM plugin appropriate to your project:
#
# require "capistrano/scm/hg"
# install_plugin Capistrano::SCM::Hg
# or
# require "capistrano/scm/svn"
# install_plugin Capistrano::SCM::Svn
# or
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Include tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rbenv
#   https://github.com/capistrano/chruby
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/rails
#   https://github.com/capistrano/passenger
#
# require "capistrano/rvm"
# require "capistrano/rbenv"
# require "capistrano/chruby"
require "capistrano/bundler"
require 'capistrano/rails'
require 'capistrano/rails/collection'

require "capistrano/rails/assets"
require "capistrano/rails/migrations"
require "capistrano/passenger/no_hook"

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }

require 'capistrano/honeybadger'
