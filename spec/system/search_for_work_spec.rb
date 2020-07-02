# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Search', type: :system, js: true, clean: true do
  let(:admin) { FactoryBot.create(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, :public) }
  let(:title) { work.title.first }

  before do
    login_as admin
    work.save!
  end

  context 'in the main search bar' do
    before { visit '/' }

    it 'finds a work by ID' do
      fill_in "search-field-header", with: work.id
      click_button "search-submit-header"
      expect(page).to have_content "1 entry found"
      expect(page).to have_content title
    end
  end

  context 'in the dashboard search bar' do
    before { visit '/dashboard/works' }

    it 'finds a work by ID' do
      fill_in "search-field-header", with: work.id
      click_button "search-submit-header"
      expect(page).to have_content "1 works in the repository"
      expect(page).to have_content title
    end

    it 'finds a work by Emory ARK' do
      fill_in "search-field-header", with: work.emory_ark.first
      click_button "search-submit-header"
      expect(page).to have_content "1 works in the repository"
      expect(page).to have_content title
    end

    it 'finds a work by other identifiers' do
      fill_in "search-field-header", with: work.other_identifiers.first
      click_button "search-submit-header"
      expect(page).to have_content "1 works in the repository"
      expect(page).to have_content title
    end

    it 'finds a work by deduplication key' do
      fill_in "search-field-header", with: work.deduplication_key
      click_button "search-submit-header"
      expect(page).to have_content "1 works in the repository"
      expect(page).to have_content title
    end

    it 'finds a work by system of record ID' do
      fill_in "search-field-header", with: work.system_of_record_ID
      click_button "search-submit-header"
      expect(page).to have_content "1 works in the repository"
      expect(page).to have_content title
    end
  end
end
