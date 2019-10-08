# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Importing records with file attachment', :perform_jobs, :clean, type: :system, js: true do
  let(:csv_file) { File.join(fixture_path, 'csv_import', 'good', 'langmuir_post_processing.csv') }

  context 'logged in as an admin user' do
    let(:collection) { FactoryBot.build(:collection_lw) }
    let(:admin_user) { FactoryBot.create(:admin) }

    before do
      ENV['IMPORT_PATH'] = Rails.root.join('spec', 'fixtures', 'fake_images').to_s
      allow(CharacterizeJob).to receive(:perform_later) # There is no fits installed on ci
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
      expect(page).to have_content 'This import will create or update 17 records.'

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
      # this is 4 because not every line in the spreadsheet is a work
      expect(CurateGenericWork.count).to eq 5
      # Ensure that all the fields got assigned as expected

      # Ensure two files get attached to the same work, when the second one doesn't have all the metadata
      # (i.e., ensure attaching the second file doesn't remove the metadata from the first file)
      work = CurateGenericWork.where(title: "*Augustine").first
      expect(work.title.first).to match(/Augustine/)
      expect(work.content_type).to eq "http://id.loc.gov/vocabulary/resourceTypes/img"
      expect(work.file_sets.count).to eq 2
      expect(work.file_sets.map { |a| a.title.first }).to contain_exactly("Front", "Back")
      expect(work.file_sets.first.pcdm_use).to eq "primary"

      # Ensure two files get attached to the same work, when the first one doesn't have all the metadata
      # (i.e., if the first one is blank, it should get stub metadata and the second one should write over its metadata)
      work = CurateGenericWork.where(title: "*Palm Beach*").first
      expect(work.title.first).to match(/Palm Beach/)
      expect(work.content_type).to eq "http://id.loc.gov/vocabulary/resourceTypes/img"
      expect(work.file_sets.count).to eq 2

      work = CurateGenericWork.where(title: "*wooden*").first
      expect(work.file_sets.count).to eq 2
    end
  end
end
