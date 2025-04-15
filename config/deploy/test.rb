# frozen_string_literal: true

set :stage, :TEST
set :honeybadger_env, 'curate-test'
set :branding_symlink_path, '/mnt/test_efs/uploads/dlp-curate/branding'
server ENV['TEST_SERVER_IP'], user: 'deploy', roles: [:web, :app, :db, :redhatapp, :collection]
