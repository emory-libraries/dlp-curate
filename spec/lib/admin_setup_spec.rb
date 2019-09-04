require 'rails_helper'
require 'admin_setup'

RSpec.describe AdminSetup, :clean do
  # Change STDOUT to "/dev/null" to block all logging output
  let(:w) { described_class.new("#{fixture_path}/config/emory/groups/admins.yml", STDOUT) }
  let(:admin_user_uid) { "adminuser001" }
  it "makes an admin Role" do
    admin = w.admin_role
    expect(admin).to be_instance_of(Role)
    expect(Role.where(name: "admin").count).to eq 1
  end
  it "loads all admins from a file" do
    w.load_admins
    expect((w.admin_role.users.map(&:uid).include? "adminuser002")).to eq true
    expect(w.admins.pluck(:uid).include?("adminuser002")).to eq true
  end
  it "makes user as admin" do
    w.make_admin(admin_user_uid)
    expect(User.where(uid: admin_user_uid).count).to eq 1
    expect((w.admin_role.users.map(&:uid).include? admin_user_uid)).to eq true
  end
  it "returns all admins" do
    s = %w[admin1 admin2 admin3]
    s.each do |t|
      w.make_admin(t)
    end
    expect(w.admins.count).to eq 3
    expect(w.admins.pluck(:uid).include?(s.first)).to be true
  end
end
