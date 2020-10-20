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
      find('a.facet_select', text: "Public").click

      expect(page).to have_selector('a.visibility-link span.label.label-success', text: 'Public')
    end
  end

  context 'when choosing Emory High Download from the visibility facet' do
    let(:work) { FactoryBot.build(:emory_high_work) }

    it 'displays the matching visibility badge in the list item' do
      find('a.facet_select', text: "Emory High Download").click

      expect(page).to have_selector('a.visibility-link span.label.label-info', text: 'Emory High Download')
    end
  end
end
