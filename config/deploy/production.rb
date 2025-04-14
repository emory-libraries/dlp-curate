# frozen_string_literal: true

set :stage, :PROD
set :honeybadger_env, 'curate'
set :branding_symlink_path, '/mnt/prod_efs/uploads/dlp-curate/branding'
server ENV['PROD_SERVER_IP'], user: 'deploy', roles: [:web, :app, :db, :redhatapp, :collection]
