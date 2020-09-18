# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing the search results page', type: :system, clean: true do
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:source_collection) { FactoryBot.create(:collection_lw, title: ['Source Collection test']) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, user: admin_user) }
  let(:admin_collection) { FactoryBot.build(:public_collection_lw, user: admin_user, with_permission_template: true, title: ['Deposit Collection test']) }
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
      expect(page).to have_selector('a.facet_select', count: 12)
    end
  end

  context 'result list item' do
    it 'has the right metadata labels' do
      expect(page).to have_css('.metadata .dl-horizontal dt', text: 'Library:')
      expect(page).to have_css('.metadata .dl-horizontal dt', text: 'Collection:')
      expect(page).to have_css('.metadata .dl-horizontal dt', text: 'Visibility:')
    end
  end

  context 'source collection is present' do
    before do
      work.source_collection_id = source_collection.id
      work.save!
    end

    it 'shows source collection for work' do
      visit '/catalog?q='
      expect(page).to have_content('Source Collection test')
    end

    context 'when faceting by source collection' do
      before { visit '/catalog?f%5Bsource_collection_title_for_works_ssim%5D%5B%5D=Source+Collection+test&locale=en&q=&search_field=all_fields' }

      it 'shows work in search results for source collection' do
        expect(page).to have_content('Test title')
        expect(page).to have_content('1 entry found')
      end

      it 'does not show deposit collections in search results' do
        expect(page).not_to have_content('Deposit Collection test')
      end
    end
  end

  context 'source collection is absent' do
    it 'shows deposit collection for work' do
      expect(page).to have_content('Deposit Collection test')
    end
  end
end
