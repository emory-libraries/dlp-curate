# frozen_string_literal: true

require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Creating a collection', :perform_jobs, clean: true, type: :system, js: true do
  context 'logged in as an admin user' do
    let(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }
    let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
    let(:admin_user) { FactoryBot.create(:admin) }
    before do
      admin_set_id
      permission_template
      login_as admin_user
    end

    it 'sucessfully creates a collection with the UI' do
      visit 'dashboard/collections/new'
      expect(page).to have_content 'New User Collection'
      fill_in 'Title', with: 'testing title'
      fill_in 'Library', with: 'testing library'
      fill_in 'Creator', with: 'creator'
      fill_in 'Description/Abstract', with: 'test'
      fill_in 'Persistent URL', with: 'https://example.org/collection'
      click_on 'Save'
      expect(page).to have_content 'Collection was successfully created'
    end
  end
end
