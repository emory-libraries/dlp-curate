# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Importing records with an invalid rights statement', :perform_jobs, :clean, type: :system, js: true do
  let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'invalid_rights_statement.csv') }

  context 'logged in as an admin user' do
    let(:collection) { FactoryBot.build(:collection_lw) }
    let(:admin_user) { FactoryBot.create(:admin) }

    before do
      allow(CharacterizeJob).to receive(:perform_later) # There is no fits installed on ci
      collection.save!
      login_as admin_user
    end

    it 'lets the user know about invalid rights statements' do
      visit '/csv_imports/new'
      expect(page).to have_content 'Testing Collection'
      expect(page).not_to have_content '["Testing Collection"]'
      select 'Testing Collection', from: "csv_import[fedora_collection_id]"

      # Fill in and submit the form
      attach_file('csv_import[manifest]', csv_file, make_visible: true)

      click_on 'Preview Import'
      # We expect to see the title of the collection on the page
      expect(page).to have_content 'Testing Collection'

      expect(page).to have_content 'This import will add 2 new records.'

      expect(page).not_to have_content 'Invalid rights_statement in row 2'
      expect(page).to have_content 'Invalid rights_statement in row 3'
    end
  end
end
