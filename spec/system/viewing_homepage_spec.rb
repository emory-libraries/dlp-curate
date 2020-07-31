# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing the homepage', type: :system do
  let(:user) { FactoryBot.create(:user) }

  context 'when contact link clicked' do
    it 'goes to the libwizard link' do
      login_as user
      visit root_path

      expect(find_link('Contact')[:href]).to eq 'https://emory.libwizard.com/f/dlp-feedback'
      expect(find_link('Contact')[:target]).to eq '_blank'
    end
  end
end
