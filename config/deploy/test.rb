set :stage, :TEST
ec2_role :app,
  user: 'deploy',
  ssh_options: 
    {
    keys: ENV['SSH_EC2_KEY_FILE'],
    forward_agent: true,
    verify_host_key: :never,
    }

# server 'PRIVATE_IP_ADDRESS', user: 'deploy', roles: [:web, :app, :db, :redhatapp]
