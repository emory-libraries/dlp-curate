# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IiifAuthService do
  let(:service) { described_class.instance }
  let(:encrypted_cookie_value) { "43BB3AA86080214273B978723D70DE6894DB9DEAC93FB27C79799EAD405B3FE8" }
  let(:spoofed_cookie_value) { "5248ED788F7352EB9E4A8CE456EC238FEC70AEF70191246E424088EBC6364C1E" }

  describe 'decrypting cookie values' do
    it 'can decrypt a valid cookie string' do
      expect(described_class.decrypt_cookie(encrypted_cookie_value)).to eq "This is a test token value"
    end

    it 'does not raise an exception when trying to decrypt an invalid cookie string' do
      expect { described_class.decrypt_cookie(spoofed_cookie_value) }.not_to raise_exception
    end
  end
end
