# frozen_string_literal: true
require 'rails_helper'

include Warden::Test::Helpers

# Deprecation Warning: As of Curate v3, Zizia and this class will be removed.
RSpec.describe 'Importing records from a Langmuir CSV', :perform_jobs, :clean, type: :system, js: true do
  let(:csv_file) { File.join(fixture_path, 'csv_import', 'good', 'langmuir_post_processing.csv') }
  let(:metadata_update_csv_file) { File.join(fixture_path, 'csv_import', 'good', 'langmuir_post_processing_update_metadata.csv') }
  let(:metadata_new_work) { File.join(fixture_path, 'csv_import', 'good', 'langmuir_post_processing_new_work.csv') }
  context 'logged in as an admin user' do
    let(:collection) { FactoryBot.build(:collection_lw) }
    let(:admin_user) { FactoryBot.create(:admin) }

    before do
      allow(CharacterizeJob).to receive(:perform_later) # There is no fits installed on ci
      collection.save!
      login_as admin_user
    end

    def upload_csv(page)
      visit '/csv_imports/new'
      expect(page).to have_content 'Testing Collection'
      expect(page).not_to have_content '["Testing Collection"]'
      select 'Testing Collection', from: "csv_import[fedora_collection_id]"
      # Fill in and submit the form
      attach_file('csv_import[manifest]', csv_file, make_visible: true)
    end

    def upload_new_work_csv(page)
      visit '/csv_imports/new'
      expect(page).to have_content 'Testing Collection'
      expect(page).not_to have_content '["Testing Collection"]'
      select 'Testing Collection', from: "csv_import[fedora_collection_id]"
      # Fill in and submit the form
      attach_file('csv_import[manifest]', metadata_new_work, make_visible: true)
    end

    def upload_metadata_only_csv(page)
      visit '/csv_imports/new'
      expect(page).to have_content 'Testing Collection'
      expect(page).not_to have_content '["Testing Collection"]'
      select 'Testing Collection', from: "csv_import[fedora_collection_id]"
      # Fill in and submit the form
      attach_file('csv_import[manifest]', metadata_update_csv_file, make_visible: true)
    end

    def start_import(page)
      # We expect to see the title of the collection on the page
      expect(page).to have_content 'Testing Collection'
      expect(page).to have_content(/This import will process (17|20) row/)
      # There is a link so the user can cancel.
      expect(page).to have_link 'Cancel', href: '/csv_imports/new?locale=en'

      # We get warnings about unsupported fields
      expect(page).to have_content('The field name "rights - digitization basis note" is not supported.')
      expect(page).not_to have_content('The field name "type" is not supported')
      expect(page).not_to have_content('The field name "intermediate_file" is not supported')
      expect(page).not_to have_content('The field name "fileset_label" is not supported')
      expect(page).not_to have_content('The field name "preservation_master_file" is not supported')
      expect(page).not_to have_content('The field name "pcdm_use" is not supported')

      # After reading the warnings, the user decides
      # to continue with the import.
      click_on 'Start Import'
      # The show page for the CsvImport
      # expect(page).to have_content 'all_fields.csv'
      expect(page).to have_content 'Start time'
      # We expect to see the title of the collection on the page
      expect(page).to have_content 'Testing Collection'
    end

    def check_details(page)
      # Viewing additional details after an import
      visit "/csv_import_details/index"
      expect(page).to have_content('Total Size')
    end

    def default_update(page)
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
      expect(work.member_of_collections).not_to eq []
    end

    def metadata_only_update(page)
      expect(CurateGenericWork.count).to eq 5
      expect(FileSet.all.size).to eq 12
      # Ensure that all the fields got assigned as expected
      work = CurateGenericWork.where(title: "*Uriel*").first
      expect(work.title.first).to match(/Uriel/)
      expect(work.content_type).to eq "http://id.loc.gov/vocabulary/resourceTypes/img"
      # Ensure that we have all the custom visibility levels
      visibilities = CurateGenericWork.all.map(&:visibility)
      expect(visibilities).to include('emory_low')
      expect(visibilities).to include('low_res')
      expect(visibilities).to include('rose_high')
      visit "/dashboard/works"
      click_on work.title.first
      expect(page).to have_content work.title.first
    end

    def delete_only_update(page)
      expect(CurateGenericWork.count).to eq 5
      # Ensure that all the fields got assigned as expected
      work = CurateGenericWork.where(title: "*City Gates*").first
      expect(work.title.first).to match(/City Gates/)
      expect(work.content_type).to eq "http://id.loc.gov/vocabulary/resourceTypes/img"
      visit "/dashboard/works"
      click_on work.title.first
      expect(page).to have_content work.title.first
    end

    def new_work_update(page)
      expect(CurateGenericWork.count).to eq 6
      # Ensure that all the fields got assigned as expected
      work = CurateGenericWork.where(title: "*Tampa*").first
      expect(work.title.first).to match(/Tampa/)
      expect(work.content_type).to eq "http://id.loc.gov/vocabulary/resourceTypes/img"
      visit "/dashboard/works"
      click_on work.title.first
      expect(page).to have_content work.title.first
    end

    def initial_import(page)
      upload_csv(page)
      click_on 'Preview Import'
      start_import(page)
      default_update(page)
      check_details(page)
    end

    def check_update_metadata_only_option(page)
      upload_metadata_only_csv(page)
      find('select#update_actor_stack_id').select("Update Existing Metadata, create new works")
      click_on 'Preview Import'
      start_import(page)
      metadata_only_update(page)
      check_details(page)
    end

    def check_update_delete_option(page)
      work = CurateGenericWork.where(title: "*City Gates*").first
      file_set_id = work.file_sets.first.id
      upload_metadata_only_csv(page)
      find('select#update_actor_stack_id').select("Overwrite All Files & Metadata")
      click_on 'Preview Import'
      start_import(page)
      metadata_only_update(page)
      check_details(page)
      expect(CurateGenericWork.where(title: "*City Gates*").first.file_sets.first.id).not_to eq file_set_id
    end

    def check_update_new_option(page)
      upload_new_work_csv(page)
      find('select#update_actor_stack_id').select("Ignore Existing Works, new works only")
      click_on 'Preview Import'
      start_import(page)
      new_work_update(page)
      check_details(page)
    end

    xit 'starts the import' do
      initial_import(page)
      check_update_metadata_only_option(page)
      check_update_delete_option(page)
      check_update_new_option(page)
    end
  end
end
