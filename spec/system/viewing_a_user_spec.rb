# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing a user page', type: :system, clean: true do
  let(:user) { FactoryBot.create(:admin, uid: 'bob') }
  let(:admin_collection) { FactoryBot.build(:public_collection_lw, user: user, with_permission_template: true) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, user: user) }
  let(:work2) { FactoryBot.build(:public_generic_work, user: user) }

  before do
    admin_collection.save!
    admin_collection.reload
    [work, work2].each do |w|
      w.save!
      w.reload
    end
    login_as user
    visit "/users/#{user.uid}"
  end

  context 'when clicking on the Collections created link' do
    it 'returns the one instance of collection in the list' do
      click_on "Collections created"

      expect(page).to have_content "1 entry found"
      within 'h3.search-result-title' do
        expect(page).to have_link(admin_collection.title.first)
      end
    end
  end

  context 'when clicking on the Works created link' do
    it 'returns the two instances of work in the list' do
      click_on "Works created"
      lis = find_all('ul.list-unstyled.catalog li')
      lis_titles = lis.map { |li| li.find('div.search-results-title-row h3.search-result-title a').text }
      work_titles = [work, work2].map { |w| w.title.first }

      expect(page).to have_content "1 - 2 of 2"
      expect(lis.size).to eq(2)
      expect(lis_titles).to match_array(work_titles)
    end
  end
end
