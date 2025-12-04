# frozen_string_literal: true
require 'ec2_ipv4_retriever'
include Ec2Ipv4Retriever

set :stage, :PROD
set :honeybadger_env, 'curate'
set :branding_symlink_path, '/mnt/prod_efs/uploads/dlp-curate/branding'
server find_ip_by_ec2_name(ec2_name: 'curate-prod.library.emory.edu') || ENV['PROD_SERVER_IP'], user: 'deploy', roles: [:web, :app, :db, :redhatapp, :collection]
