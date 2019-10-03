# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Depositing items into a migration collection', :perform_jobs, :clean, type: :system, js: true do
  let(:library_collection_type) { Curate::CollectionType.find_or_create_library_collection_type }
  let(:collections_csv_file) { fixture_path + "/csv_import/collections/collections.csv" }
  let(:admin_user) { FactoryBot.create(:admin) }
  before do
    allow(Role).to receive(:exists?).and_return(true)
    Curate::CollectionType.find_or_create_library_collection_type
    CurateCollectionImporter.new.import(collections_csv_file)
  end
  let(:langmuir) { Collection.where(local_call_number: "MSS1218").first }
  let(:yellowbacks) { Collection.where(local_call_number: "YELLOWBACKS").first }

  context 'logged in as an admin user' do
    before do
      allow(CharacterizeJob).to receive(:perform_later) # There is no fits installed on ci
      login_as admin_user
    end

    it 'shows that Repository Administrators have rights on Library Collection objects' do
      visit "/dashboard/collections/#{langmuir.id}/edit?locale=en#sharing"
      expect(page).to have_content 'Repository Administrators'

      hpt = Hyrax::PermissionTemplate.where(source_id: langmuir.id).first
      hpta_count = Hyrax::PermissionTemplateAccess.where(
        permission_template_id: hpt.id,
        agent_type: "group",
        agent_id: "admin",
        access: "manage"
      ).count
      expect(hpta_count).to eq 1
    end

    it 'saves langmuir collection data' do
      visit "/dashboard/collections/#{langmuir.id}"
      expect(page).to have_content "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      expect(page).to have_content "Collection of photographs depicting African American life and culture collected by Robert Langmuir."
    end

    it 'saves yellowbacks collection data' do
      visit "/dashboard/collections/#{yellowbacks.id}"
      expect(page).to have_content "Chester W. Topp collection of Victorian yellowbacks and paperbacks"
      expect(page).to have_content "https://yellowbacks.digitalscholarship.emory.edu/"
    end
  end
end
