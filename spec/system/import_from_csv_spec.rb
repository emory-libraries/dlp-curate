# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Importing records from a CSV file', :perform_jobs, :clean, type: :system, js: true do
  let(:csv_file) { File.join(fixture_path, 'csv_import', 'zizia_basic.csv') }

  context 'logged in as an admin user' do
    let(:collection) { FactoryBot.build(:collection_lw) }
    let(:admin_user) { FactoryBot.create(:admin) }

    before do
      allow(CharacterizeJob).to receive(:perform_later) # There is no fits installed on travis-ci
      collection.save!
      login_as admin_user
    end

    it 'starts the import' do
      visit '/csv_imports/new'
      expect(page).to have_content 'Testing Collection'
      expect(page).not_to have_content '["Testing Collection"]'
      select 'Testing Collection', from: "csv_import[fedora_collection_id]"

      # Fill in and submit the form
      attach_file('csv_import[manifest]', csv_file, make_visible: true)

      click_on 'Preview Import'

      # We expect to see the title of the collection on the page
      expect(page).to have_content 'Testing Collection'

      expect(page).to have_content 'This import will add 3 new records.'

      # There is a link so the user can cancel.
      expect(page).to have_link 'Cancel', href: '/csv_imports/new?locale=en'

      # After reading the warnings, the user decides
      # to continue with the import.
      click_on 'Start Import'

      # The show page for the CsvImport
      # expect(page).to have_content 'all_fields.csv'
      expect(page).to have_content 'Start time'

      # We expect to see the title of the collection on the page
      expect(page).to have_content 'Testing Collection'

      # Let the background jobs run, and check that the expected number of records got created.
      expect(CurateGenericWork.count).to eq 3

      # Ensure that all the fields got assigned as expected
      work = CurateGenericWork.where(title: "*Dog*").first
      expect(work.title.first).to match(/Dog/)

      visit "/dashboard/works"
      click_on 'A Cute Dog'
      expect(page).to have_content work.title.first
    end
  end
end
