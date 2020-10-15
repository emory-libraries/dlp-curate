# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing the homepage', type: :system do
  let(:user) { FactoryBot.create(:admin) }

  before do
    login_as user
    visit root_path
  end

  context 'when contact link clicked' do
    it 'goes to the libwizard link' do
      expect(find_link('Contact')[:href]).to eq 'https://emory.libwizard.com/f/dlp-feedback'
      expect(find_link('Contact')[:target]).to eq '_blank'
    end
  end

  it "doesn't show Terms of Use or Share Your Work links" do
    expect(page).not_to have_link('Share Your Work')
    expect(page).not_to have_link('Terms of Use')
  end
end
