# frozen_string_literal: true

require 'rails_helper'
include Warden::Test::Helpers

# Testing whether the new ColletionType attribute shows up on the list of settings
# and whether it persists when assigned.
RSpec.describe 'CollectionType deposit_only_collection settings', :clean, type: :system do
  let(:user) { FactoryBot.create(:admin) }
  before do
    login_as user
    visit '/admin/collection_types'
    click_on 'Create new collection type'
    fill_in 'Type name', with: 'Posters'
    click_on 'Save'
    find('a[href="#settings"]').click
  end

  context 'after new CollectionType created, settings' do
    it 'has a checkbox for Deposit-Only Collection' do
      expect(page).to have_field 'collection_type[deposit_only_collection]'
      expect(page).to have_css('label', text: 'DEPOSIT-ONLY COLLECTION')
    end

    it 'persists the true state of Deposit-Only' do
      check 'DEPOSIT-ONLY COLLECTION'
      click_on 'Save changes'
      find('a[href="#settings"]').click
      checked_deposit_only_box = page.find('#collection_type_deposit_only_collection')['checked']

      expect(checked_deposit_only_box).to be_truthy
    end
  end
end
