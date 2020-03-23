# frozen_string_literal: true

set :branding_symlink_path, ENV['BRANDING_SYMLINK_PATH'] || 'unset'
server '127.0.0.1', user: 'deploy', roles: [:web, :app, :db, :redhatapp, :collection]
