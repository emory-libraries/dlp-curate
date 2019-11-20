# frozen_string_literal: true

server 'curate-cd.curationexperts.com', user: 'deploy', roles: [:web, :app, :db, :ubuntuapp, :collection]
set :init_system, :systemd # see https://github.com/seuros/capistrano-sidekiq#integration-with-systemd
set :service_unit_name, "sidekiq.service"
