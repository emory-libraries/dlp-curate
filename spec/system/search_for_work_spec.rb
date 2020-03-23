# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Search', type: :system, js: true do
  let(:admin) { FactoryBot.create(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, :public) }
  let(:title) { work.title.first }

  before do
    login_as admin
    work.save!
  end

  it 'finds a work by ID' do
    login_as admin
    visit '/'
    fill_in "search-field-header", with: work.id
    click_button "search-submit-header"
    expect(page).to have_content "1 entry found"
    expect(page).to have_content title
  end
end
