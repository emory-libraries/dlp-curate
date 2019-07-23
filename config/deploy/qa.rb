# frozen_string_literal: true
server 'curate-qa.curationexperts.com', user: 'deploy', roles: [:web, :app, :db, :ubuntuapp]
set :repo_url, "https://github.com/curationexperts/dlp-curate.git"

namespace :deploy do
  after :finishing, :restart_apache do
    on roles(:ubuntuapp) do
      execute :sudo, :systemctl, :restart, :apache2
    end
  end
end
