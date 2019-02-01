require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Admin dashboard', integration: true do
  context 'as a non-admin user' do
    let(:user) { FactoryBot.create(:user) }

    before do
      login_as user
      visit '/dashboard'
    end

    scenario 'does not have settings tab' do
      expect(page).not_to have_link 'Settings'
    end
  end

  context 'as an admin user' do
    let(:admin) { FactoryBot.create(:admin) }

    before do
      login_as admin
      visit '/dashboard'
    end

    scenario 'view the workflow roles page' do
      click_on 'Workflow Roles'
      expect(page).to have_content 'Assign Role'
    end

    scenario 'does have settings tab' do
      expect(page).to have_link 'Settings'
    end

    # TODO: Add more admin tests, for eg: stats page, when work is created

    # scenario 'view the statistics page' do
    # 	click_on 'Reports'
    # 	expect(page).to have_content ''
    # end
  end
end
