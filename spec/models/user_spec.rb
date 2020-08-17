# frozen_string_literal: true

require 'rails_helper'
RSpec.describe User, :clean do
  before do
    # User must exists before tests can run
    described_class.create(provider:     'shibboleth',
                           uid:          'brianbboys1967',
                           ppid:         'P0000001',
                           display_name: 'Brian Wilson')
  end

  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: 'shibboleth',
      uid:      "P0000001",
      info:     {
        display_name: "Brian Wilson",
        uid:          'brianbboys1967'
      }
    )
  end
  let(:user) { described_class.from_omniauth(auth_hash) }

  context "has attributes" do
    it "has Shibboleth as a provider" do
      expect(user.provider).to eq 'shibboleth'
    end
    it "has a uid" do
      expect(user.uid).to eq auth_hash.info.uid
    end
    it "has a name" do
      expect(user.display_name).to eq auth_hash.info.display_name
    end
    it "has a PPID" do
      expect(user.ppid).to eq auth_hash.uid
    end
  end

  context "updating an existing user" do
    let(:updated_auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'shibboleth',
        uid:      "P0000002",
        info:     {
          display_name: "Boaty McBoatface",
          uid:          'brianbboys1967'
        }
      )
    end

    it "updates ppid and display_name with values from shibboleth" do
      expect(user.uid).to eq auth_hash.info.uid
      expect(user.ppid).to eq auth_hash.uid
      expect(user.display_name).to eq auth_hash.info.display_name
      described_class.from_omniauth(updated_auth_hash)
      user.reload
      expect(user.uid).to eq auth_hash.info.uid
      expect(user.ppid).not_to eq auth_hash.uid
      expect(user.ppid).to eq updated_auth_hash.uid
      expect(user.display_name).not_to eq auth_hash.info.display_name
      expect(user.display_name).to eq updated_auth_hash.info.display_name
    end
  end

  context "signing in twice" do
    it "finds the original account instead of trying to make a new one" do
      # login existing user second time
      expect { described_class.from_omniauth(auth_hash) }
        .not_to change { described_class.count }
    end
  end

  context "attempting to sign in a new user" do
    let(:new_auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'shibboleth',
        uid:      'P0000003',
        info:     {
          display_name: 'Fake Person',
          uid:          'egnetid'
        }
      )
    end

    it "does not allow a new user to sign in" do
      expect { described_class.from_omniauth(new_auth_hash) }
        .not_to change { described_class.count }
      expect(Rails.logger).to receive(:error)
      u = described_class.from_omniauth(new_auth_hash)
      expect(u.class.name).to eql 'User'
      expect(u.persisted?).to be false
    end
  end

  context "invalid shibboleth data" do
    let(:invalid_auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'shibboleth',
        uid:      '',
        info:     {
          display_name: '',
          uid:          ''
        }
      )
    end

    it "does not register new users" do
      expect { described_class.from_omniauth(invalid_auth_hash) }
        .not_to change { described_class.count }
      expect(Rails.logger).to receive(:error)
      u = described_class.from_omniauth(invalid_auth_hash)
      expect(u.class.name).to eql 'User'
      expect(u.persisted?).to be false
    end
  end

  context "using user factories" do
    it "makes a user with expected shibboleth fields" do
      user = FactoryBot.create(:user)
      expect(user.display_name).to be_instance_of String
      expect(user.uid).to be_instance_of String
      expect(user.valid?).to be_truthy
    end
  end

  context "making a system user" do
    it "gives the user elevated privileges" do
      u = described_class.find_or_create_system_user(user.uid)
      expect(u.uid).to eq user.uid
      # TODO: test that the user does have the elevated privileges.
    end
  end

  context '#viewer?' do
    it "returns true if any of user's roles contains viewer" do
      role = Role.find_or_create_by(name: 'health_sciences_viewer')
      user.roles << role

      expect(user.viewer?).to be_truthy
    end

    it "returns false is user has no roles" do
      expect(user.viewer?).to be_falsey
    end

    it "returns false is user has roles but none containing viewer" do
      role = Role.find_or_create_by(name: 'admin')
      user.roles << role

      expect(user.viewer?).to be_falsey
    end
  end
end
