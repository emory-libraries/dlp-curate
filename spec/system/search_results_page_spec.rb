# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing the search results page', type: :system, clean: true do
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, user: admin_user) }
  let(:admin_collection) { FactoryBot.build(:public_collection_lw, user: admin_user, with_permission_template: true) }
  before do
    login_as admin_user
    work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    work.member_of_collections = [admin_collection]
    work.save!
    work.reload
    visit '/catalog?q='
  end

  context 'facet text' do
    include_examples "check_page_for_multiple_text",
      [
        'Library',
        'Collection',
        'Creator',
        'Format',
        'Genre',
        'Language',
        'Date',
        'Publication Date',
        'Subject - Topics',
        'Subject - Names',
        'Subject - Geographic',
        'Rights Status',
        'Access'
      ],
      'checking for right labels'
  end

  context 'facet_selects' do
    it 'has the right count of facet_selects' do
      expect(page).to have_selector('a.facet_select', count: 13)
    end
  end
end
