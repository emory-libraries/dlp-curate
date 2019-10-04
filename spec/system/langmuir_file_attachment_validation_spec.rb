# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Importing records with a bad file attachment', :perform_jobs, :clean, type: :system, js: true do
  let(:csv_file) { File.join(fixture_path, 'csv_import', 'csv_files_with_problems', 'batch_with_bad_filename.csv') }

  context 'logged in as an admin user' do
    let(:collection) { FactoryBot.build(:collection_lw) }
    let(:admin_user) { FactoryBot.create(:admin) }

    before do
      ENV['IMPORT_PATH'] = Rails.root.join('spec', 'fixtures', 'fake_images').to_s
      allow(CharacterizeJob).to receive(:perform_later) # There is no fits installed on ci
      collection.save!
      login_as admin_user
    end

    it 'starts the import and gets a warning message' do
      visit '/csv_imports/new'
      expect(page).to have_content 'Testing Collection'
      expect(page).not_to have_content '["Testing Collection"]'
      select 'Testing Collection', from: "csv_import[fedora_collection_id]"

      # Fill in and submit the form
      attach_file('csv_import[manifest]', csv_file, make_visible: true)

      click_on 'Preview Import'

      expect(page).to have_content "row 2: Unable to find"
      expect(page).to have_content "ARCH.tif"
    end
  end
end
