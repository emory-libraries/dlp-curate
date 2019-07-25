# frozen_string_literal: true
namespace :dce do
  desc "Set up DCE database accounts"
  task account_setup: :environment do
    u = ::User.find_or_create_by(uid: 'admin')
    u.email = 'systems@curationexperts.com'
    u.display_name = "Default Admin"
    u.password = ENV['ADMIN_PASSWORD'] || 'password'
    u.save
    admin_role = Role.find_or_create_by(name: 'admin')
    admin_role.users << u
    admin_role.save

    puts "Created DCE default admin account"

    u = ::User.find_or_create_by(uid: 'user')
    u.email = 'contact@curationexperts.com'
    u.display_name = "Ordinary User"
    u.password = ENV['ADMIN_PASSWORD'] || 'password'
    u.save

    puts "Created DCE default user account"
  end
end
