require 'rails_helper'

auth_hash = OmniAuth::AuthHash.new(
  provider: 'shibboleth',
  uid: "P8806459",
  info: {
    display_name: "Brian Wilson",
    uid: 'brianbboys1967'
  }
)

RSpec.describe User, :clean do
  context "shibboleth" do
    let(:user) { described_class.from_omniauth(auth_hash) }
    it "has a shibboleth provided name" do
      expect(user.display_name).to eq auth_hash.info.display_name
    end
    it "has a shibboleth provided uid" do
      expect(user.uid).to eq auth_hash.info.uid
    end
  end
  context "updating an existing user" do
    let(:user) do
      user = described_class.new(provider: "shibboleth", uid: "fake", display_name: nil)
      user.save
      user
    end
    let(:fake_auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'shibboleth',
        uid: "P0001",
        info: {
          display_name: "Boaty McBoatface",
          uid: 'fake'
        }
      )
    end
  end
  context "signing in twice" do
    it "finds the original account instead of trying to make a new one" do
      # create user first time
      expect { described_class.from_omniauth(auth_hash) }
        .to change { described_class.count }
        .by(1)

      # login existing user second time
      expect { described_class.from_omniauth(auth_hash) }
        .not_to change { described_class.count }
    end
  end
  context "invalid shibboleth data" do
    let(:invalid_auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'shibboleth',
        uid: '',
        info: {
          display_name: '',
          uid: ''
        }
      )
    end
    it "does not create a new user" do
      # do not create a new user if uid is blank
      expect { described_class.from_omniauth(invalid_auth_hash) }
        .not_to change { described_class.count }
    end
  end
  context "user factories" do
    it "makes a user with expected shibboleth fields" do
      user = FactoryBot.create(:user)
      expect(user.display_name).to be_instance_of String
      expect(user.uid).to be_instance_of String
    end
  end
  it "makes a system user" do
    user_key = "fake_user_key"
    u = ::User.find_or_create_system_user(user_key)
    expect(u.uid).to eq(user_key)
  end
end
