# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Filtering on the Dashboard Works page', type: :system, clean: true do
  let(:admin) { FactoryBot.create(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, :public) }

  before do
    login_as admin
    work.save!
    visit '/dashboard/works'
  end

  context 'when choosing Public from the visibility facet' do
    it 'displays the matching visibility badge in the list item' do
      click_button 'Visibility'
      click_link 'Public', class: 'facet-select'

      expect(page).to have_selector('span.constraint-value span.filter-value', text: 'Public')
    end
  end

  context 'when choosing Emory High Download from the visibility facet' do
    let(:work) { FactoryBot.build(:emory_high_work) }

    it 'displays the matching visibility badge in the list item' do
      click_button 'Visibility'
      click_link 'Emory High Download', class: 'facet-select'

      expect(page).to have_selector('span.constraint-value span.filter-value', text: 'Emory High Download')
    end
  end
end
