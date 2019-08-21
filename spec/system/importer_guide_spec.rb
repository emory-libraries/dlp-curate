# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing the importer guide', type: :system do
  let(:admin_user) { FactoryBot.create(:admin) }
  before do
    login_as admin_user
  end

  it 'displays without error' do
    visit '/importer_documentation/guide'
    expect(page.title).to eq('Show Metadata Detail // Curate')
  end
end
