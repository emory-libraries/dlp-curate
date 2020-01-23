# frozen_string_literal: true

set :stage, :ARCH
set :honeybadger_env, "curate-arch"
set :init_system, :systemd

ec2_role [:web, :app, :db, :redhatapp, :collection],
         user:        'deploy',
         ssh_options: {
           keys:            ENV['SSH_EC2_KEY_FILE'],
           forward_agent:   true,
           verify_host_key: :never
         }
# server 'PRIVATE_IP_Address', user: 'deploy', roles: [:web, :app, :db, :redhatapp, :collection]
