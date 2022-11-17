# frozen_string_literal: true
require 'rails_helper'

RSpec.describe OmniauthCallbacksController do
  before do
    User.create(provider:     'shibboleth',
                uid:          'brianbboys1967',
                ppid:         'P0000001',
                display_name: 'Brian Wilson')
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:shib]
  end
  OmniAuth.config.mock_auth[:shib] =
    OmniAuth::AuthHash.new(
      provider: 'shibboleth',
      uid:      "P0000001",
      info:     {
        display_name: "Brian Wilson",
        uid:          'brianbboys1967'
      }
    )

  context "when origin is present" do
    before do
      request.env["omniauth.origin"] = '/example'
      post :shibboleth
    end

    it "redirects to origin" do
      expect(response.redirect_url).to eq 'http://test.host/example'
    end

    it "does not redirect to a 404" do
      expect(response.status).not_to eq 404
    end
  end

  context "when origin is missing" do
    before { post :shibboleth }

    it "redirects to dashboard" do
      expect(response.redirect_url).to include 'http://test.host/dashboard'
    end

    it "does not redirect to a 404" do
      expect(response.status).not_to eq 404
    end
  end
end
