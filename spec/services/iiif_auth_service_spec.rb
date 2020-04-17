# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IiifAuthService, iiif: true do
  let(:service) { described_class.instance }
  let(:encrypted_cookie_value) { "BE0F7323469F3E7DF86CF9CA95B8ADD5D17753DA4F00BB67F2A9E8EC93E6A370" }
  let(:spoofed_cookie_value) { "5248ED788F7352EB9E4A8CE456EC238FEC70AEF70191246E424088EBC6364C1E" }

  describe 'decrypting cookie values' do
    it 'can decrypt a valid cookie string' do
      expect(described_class.decrypt_cookie(encrypted_cookie_value)).not_to be false
    end

    it 'does not raise an exception when trying to decrypt an invalid cookie string' do
      expect { described_class.decrypt_cookie(spoofed_cookie_value) }.not_to raise_exception
    end
  end
end
