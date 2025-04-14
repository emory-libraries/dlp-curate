# frozen_string_literal: true

# config valid for current version and patch releases of Capistrano
lock "~> 3.19.2"

# Load environment variables
require 'dotenv'

Dotenv.load('.env.development')

set :application, "dlp-curate"
set :repo_url, "https://github.com/emory-libraries/dlp-curate.git"
set :deploy_to, '/opt/dlp-curate'
set :rails_env, 'production'
set :assets_prefix, "#{shared_path}/public/assets"
set :migration_role, :app
set :service_unit_name, "sidekiq.service"
set :passenger_restart_with_touch, true

SSHKit.config.command_map[:rake] = 'bundle exec rake'
set :branch, ENV['REVISION'] || ENV['BRANCH'] || ENV['BRANCH_NAME'] || 'master'

append :linked_dirs, "log", "public/assets", "tmp/pids", "tmp/cache", "tmp/sockets",
  "tmp/imports", "config/emory/groups", "tmp/csv_uploads", "tmp/csv_uploads_cache"
append :linked_files, ".env.production", "config/secrets.yml", "config/reading_room_ips.yml"

set :default_env,
    PATH:                            '$PATH:/opt/rh/rh-ruby25/root/usr/local/bin:/opt/rh/rh-ruby25/root/usr/bin',
    LD_LIBRARY_PATH:                 '$LD_LIBRARY_PATH:/opt/rh/rh-ruby25/root/usr/local/lib64:/opt/rh/rh-ruby25/root/usr/lib64',
    PASSENGER_INSTANCE_REGISTRY_DIR: '/var/run'

# Default value for local_user is ENV['USER']
set :local_user, -> { `git config user.name`.chomp }

# Restart passenger after deploy is finished
after :'deploy:finished', :'passenger:restart'

# Restart apache on RedHat
namespace :deploy do
  after :finishing, :restart_apache do
    on roles(:redhatapp) do
      execute :sudo, :systemctl, :restart, :httpd
    end
  end
end

namespace :sidekiq do
  task :restart do
    invoke 'sidekiq:stop'
    invoke 'sidekiq:start'
  end

  before 'deploy:finished', 'sidekiq:restart'

  task :stop do
    on roles(:app) do
      execute :sudo, :systemctl, :stop, :sidekiq
    end
  end

  task :start do
    on roles(:app) do
      execute :sudo, :systemctl, :start, :sidekiq
    end
  end
end

# Restart apache on Ubuntu
namespace :deploy do
  after :finishing, :restart_apache do
    on roles(:ubuntuapp) do
      execute :sudo, :systemctl, :restart, :apache2
    end
  end
end

# Setup DCE accounts on Ubuntu
namespace :deploy do
  after :finishing, :dce_accounts do
    on roles(:ubuntuapp) do
      execute "cd #{current_path} && RAILS_ENV=production bundle exec rake dce:account_setup"
    end
  end
end

# On deploy, ensure library collection type exists
namespace :deploy do
  after :finishing, :create_library_collection_type do
    on roles(:collection) do
      execute "cd #{current_path} && RAILS_ENV=production bundle exec rake curate:create_library_collection_type"
    end
  end
end

namespace :deploy do
  after :finishing, :create_migration_collections do
    on roles(:collection) do
      execute "cd #{current_path} && RAILS_ENV=production bundle exec rake curate:collections:migration_setup"
    end
  end
end

namespace :deploy do
  desc "Add symlink for branding folder when variable is defined"
  before :finishing, :create_branding_path_symlink do
    on roles(:app) do
      symlink_path = fetch(:branding_symlink_path, 'unset')
      if symlink_path != 'unset'
        execute "ln -sf #{symlink_path} #{release_path}/public"
      else
        info "branding_symlink_path is unset, skipping task *create_branding_path_symlink*"
      end
    end
  end
end

namespace :deploy do
  desc 'Ask user for CAB approval before deployment if stage is PROD'
  task :confirm_cab_approval do
    if fetch(:stage) == :PROD
      ask(:cab_acknowledged, 'Have you submitted and received CAB approval? (Yes/No): ')
      unless /^y(es)?$/i.match?(fetch(:cab_acknowledged))
        puts 'Please submit a CAB request and get it approved before proceeding with deployment.'
        exit
      end
    end
  end
end

before 'deploy:starting', 'deploy:confirm_cab_approval'
