# frozen_string_literal: true

set :stage, :ARCH
set :honeybadger_env, 'curate-arch'
set :branding_symlink_path, '/mnt/arch_efs/uploads/dlp-curate/branding'
server ENV['ARCH_SERVER_IP'], user: 'deploy', roles: [:web, :app, :db, :redhatapp, :collection]
