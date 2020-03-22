# frozen_string_literal: true

set :branding_symblink_path, ENV['BRANDING_SYMBLINK_PATH'] || 'unset'
server '127.0.0.1', user: 'deploy', roles: [:web, :app, :db, :redhatapp, :collection]
