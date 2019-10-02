# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Search', type: :system do
  let(:admin_user) { FactoryBot.build(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, :public) }

  before do
    login_as admin_user
    work.save!
  end

  it 'finds a work by ID' do
    visit root_path
    fill_in "search-field-header", with: work.id
    click_button "search-submit-header"
    expect(page).to have_content "1 entry found"
    expect(page).to have_content "Test title"
  end
end
