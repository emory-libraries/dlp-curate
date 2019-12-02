# frozen_string_literal: true
server '127.0.0.1', user: 'deploy', roles: [:web, :app, :db, :ubuntuapp, :collection]
set :default_env,
    PASSENGER_INSTANCE_REGISTRY_DIR: '/var/run/passenger-instreg'
