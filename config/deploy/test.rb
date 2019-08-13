set :stage, :TEST
ec2_role [:web, :app, :db, :redhatapp],
  user: 'deploy',
  ssh_options: {
    keys: ENV['SSH_EC2_KEY_FILE'],
    forward_agent: true,
    verify_host_key: :never,
    }
# server 'PRIVATE_IP_Address', user: 'deploy', roles: [:web, :app, :db, :redhatapp]

