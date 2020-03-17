# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IiifAuthService do
  let(:service) { described_class.instance }
  let(:encrypted_cookie_value) { "43BB3AA86080214273B978723D70DE6894DB9DEAC93FB27C79799EAD405B3FE8" }

  describe 'first test' do
    it 'can decrypt a string' do
      expect(IiifAuthService.decrypt_cookie(encrypted_cookie_value)).to eq "This is a test token value"
    end
  end
end
