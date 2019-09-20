# frozen_string_literal: true
require 'rails_helper'
require 'user_setup'

RSpec.describe UserSetup, :clean do
  context "rose manager" do
    # Change "/dev/null" to STDOUT to unblock all logging output
    let(:w) { described_class.new("#{fixture_path}/config/emory/groups/rose_manager.yml", "/dev/null") }
    let(:user_uid) { "rosemanager001" }
    it "makes Rose Manager role" do
      rose_manager = w.user_role
      expect(rose_manager).to be_instance_of(Role)
      expect(Role.where(name: "rose_manager").count).to eq 1
    end
    it "loads all users from a file" do
      w.load_users
      expect((w.user_role.users.map(&:uid).include? "rosemanager002")).to eq true
      expect(w.user_role.users.pluck(:uid).include?("rosemanager002")).to eq true
    end
    it "adds user to specific user_group" do
      w.add_user(user_uid)
      expect(User.where(uid: user_uid).count).to eq 1
      expect((w.user_role.users.map(&:uid).include? user_uid)).to eq true
    end
    it "returns all users" do
      s = %w[user1 user2 user3]
      s.each do |t|
        w.add_user(t)
      end
      expect(w.user_role.users.count).to eq 3
      expect(w.user_role.users.pluck(:uid).include?(s.first)).to be true
    end
  end
  context "rose viewer" do
    # Change "/dev/null" to STDOUT to unblock all logging output
    let(:w) { described_class.new("#{fixture_path}/config/emory/groups/rose_viewer.yml", "/dev/null") }
    let(:user_uid) { "roseviewer001" }
    it "makes Rose Viewer role" do
      rose_viewer = w.user_role
      expect(rose_viewer).to be_instance_of(Role)
      expect(Role.where(name: "rose_viewer").count).to eq 1
    end
    it "loads all users from a file" do
      w.load_users
      expect((w.user_role.users.map(&:uid).include? "roseviewer002")).to eq true
      expect(w.user_role.users.pluck(:uid).include?("roseviewer002")).to eq true
    end
    it "adds user to specific user_group" do
      w.add_user(user_uid)
      expect(User.where(uid: user_uid).count).to eq 1
      expect((w.user_role.users.map(&:uid).include? user_uid)).to eq true
    end
    it "returns all users" do
      s = %w[user1 user2 user3]
      s.each do |t|
        w.add_user(t)
      end
      expect(w.user_role.users.count).to eq 3
      expect(w.user_role.users.pluck(:uid).include?(s.first)).to be true
    end
  end
end
