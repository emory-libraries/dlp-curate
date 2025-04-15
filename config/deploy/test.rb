# frozen_string_literal: true
require 'ec2_ipv4_retriever'
include Ec2Ipv4Retriever

set :stage, :TEST
set :honeybadger_env, 'curate-test'
set :branding_symlink_path, '/mnt/test_efs/uploads/dlp-curate/branding'
server find_ip_by_ec2_name(ec2_name: 'curate-test.library.emory.edu') || ENV['TEST_SERVER_IP'], user: 'deploy', roles: [:web, :app, :db, :redhatapp, :collection]
