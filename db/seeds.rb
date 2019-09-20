# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'admin_setup'
# Initialize AdminSetup class
a = AdminSetup.new
# Setup admins
a.setup

require 'user_setup'
Dir.glob("#{::Rails.root}/config/emory/groups/*.yml") do |yml_file|
  unless yml_file.include?("admin")
    # Initialize UserSetup class
    u = UserSetup.new(yml_file)
    # Add users to user_group
    u.setup
  end
end
