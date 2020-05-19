# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Viewing collections', type: :system, clean: true do
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:admin_collection) { FactoryBot.build(:public_collection_lw, user: admin_user, with_permission_template: true) }
  let(:user) { FactoryBot.create(:user) }
  let(:user_collection) { FactoryBot.build(:public_collection_lw, user: user, with_permission_template: true) }

  before do
    admin_collection.save!
    admin_collection.reload
    user_collection.save!
    user_collection.reload
  end

  context 'when logged in as an admin' do
    it 'has a delete action on the my collections dashboard' do
      login_as admin_user
      visit "/dashboard/my/collections"
      expect(page).to have_selector(:css, 'a[title="Delete collection"]')
    end

    it 'has a delete action on the all collections dashboard' do
      login_as admin_user
      visit "/dashboard/collections"
      expect(page).to have_selector(:css, 'a[title="Delete collection"]')
    end

    it 'has a delete action on the individual collection dashboard page' do
      login_as admin_user
      visit "/dashboard/collections/#{admin_collection.id}"
      expect(page).to have_selector(:css, 'a[title="Delete this collection"]')
    end
  end

  context 'when logged in as a non-admin user' do
    it 'does not have a delete action on the my collections dashboard' do
      login_as user
      visit "/dashboard/my/collections"
      expect(page).to have_selector(:css, 'a[title="Edit collection"]')
      expect(page).not_to have_selector(:css, 'a[title="Delete collection"]')
    end

    it 'does not have a delete action on the all collections dashboard' do
      login_as user
      visit "/dashboard/collections"
      expect(page).not_to have_selector(:css, 'a[title="Delete collection"]')
    end

    it 'does not have a delete action on the individual collection dashboard page' do
      login_as user
      visit "/dashboard/collections/#{user_collection.id}"
      expect(page).to have_selector(:css, 'a[title="Edit this collection"]')
      expect(page).not_to have_selector(:css, 'a[title="Delete this collection"]')
    end
  end
end
