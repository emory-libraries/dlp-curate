# frozen_string_literal: true
require 'ec2_ipv4_retriever'
include Ec2Ipv4Retriever

set :stage, :ARCH
set :honeybadger_env, 'curate-arch'
set :branding_symlink_path, '/mnt/arch_efs/uploads/dlp-curate/branding'
server find_ip_by_ec2_name(ec2_name: 'curate-arch.library.emory.edu') || ENV['ARCH_SERVER_IP'], user: 'deploy', roles: [:web, :app, :db, :ubuntu, :collection]
