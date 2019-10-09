# frozen_string_literal: true
require 'rails_helper'

include Warden::Test::Helpers

RSpec.describe 'Importing records from a Langmuir CSV', :perform_jobs, :clean, type: :system, js: true do
  let(:csv_file) { File.join(fixture_path, 'csv_import', 'good', 'langmuir_post_processing.csv') }

  context 'logged in as an admin user' do
    let(:collection) { FactoryBot.build(:collection_lw) }
    let(:admin_user) { FactoryBot.create(:admin) }

    before do
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
      expect(CurateGenericWork.count).to eq 5

      # Ensure that all the fields got assigned as expected
      work = CurateGenericWork.where(title: "*City gates*").first
      expect(work.title.first).to match(/City gates/)

      # No resource type in the CSV
      expect(work.content_type).to eq "http://id.loc.gov/vocabulary/resourceTypes/img"

      # Ensure that we have all the custom visibility levels
      visibilities = CurateGenericWork.all.map(&:visibility)
      expect(visibilities).to include('emory_low')
      expect(visibilities).to include('low_res')
      expect(visibilities).to include('rose_high')

      visit "/dashboard/works"
      click_on work.title.first
      expect(page).to have_content work.title.first

      # Viewing additional details after an import
      visit "/csv_import_details/index"

      expect(page).to have_content('Total Size in Bytes')

      # Bring back these checks when csv import details returns
      find(:xpath, '//*[@id="content-wrapper"]/table/tbody/tr[2]/td[1]/a').click
      expect(page).to have_content('MSS1218_B071_I205_P0001_PROD.tif')
      expect(page).to have_content('MSS1218_B071_I205_P0001_ARCH.tif')
      expect(page).to have_content('162784')
    end
  end
end
