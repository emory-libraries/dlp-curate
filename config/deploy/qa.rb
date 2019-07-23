# frozen_string_literal: true
server 'curate-qa.curationexperts.com', user: 'deploy', roles: [:ubuntu]
namespace :deploy do
  after :finishing, :restart_apache do
    on roles(:ubuntu) do
      execute :sudo, :systemctl, :restart, :apache2
    end
  end
end
