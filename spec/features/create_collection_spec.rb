require 'rails_helper'
include Warden::Test::Helpers

RSpec.feature 'Create a collection' do
  context 'with a logged in user' do
    let(:user_attributes) do
      { uid: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end

    before do
      Hyrax::CollectionType.find_or_create_default_collection_type
      login_as user
    end

    scenario "input fields are present", js: true do
      visit("dashboard/collections/new?collection_type_id=1")

      expect(page).to have_css("input#collection_title")

      click_link('Additional fields')
      expect(page).to have_css("input#collection_creator")
      expect(page).to have_content("Add another Creator")
    end
  end
end
