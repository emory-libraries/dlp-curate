require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Sidekiq dashboard', integration: true do
  context 'as a non-admin user' do
    let(:user) { FactoryBot.create(:user) }
    before do
      login_as user
    end

    scenario 'does not have settings tab' do
      expect { visit '/sidekiq' }.to raise_exception ActionController::RoutingError
    end
  end

  context 'as an admin user' do
    let(:admin) { FactoryBot.create(:admin) }
    before do
      login_as admin
      visit '/sidekiq'
    end

    scenario 'view the active sidekiq queues' do
      click_on 'Busy'
      expect(page).to have_content 'Processes'
    end
  end
end
