# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'Depositing items into a migration collection', :perform_jobs, :clean, type: :system, js: true do
  let(:library_collection_type) { Curate::CollectionType.find_or_create_library_collection_type }
  let(:langmuir_csv_file) { Rails.root.join('config', 'collection_metadata', 'langmuir_collection.csv') }
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:collection) do
    Curate::CollectionType.find_or_create_library_collection_type
    CurateCollectionImporter.new.import(langmuir_csv_file)
    Collection.last
  end

  context 'logged in as an admin user' do
    before do
      allow(CharacterizeJob).to receive(:perform_later) # There is no fits installed on ci
      login_as admin_user
    end

    it 'shows that Repository Administrators have rights on Library Collection objects' do
      visit "/dashboard/collections/#{collection.id}/edit?locale=en#sharing"
      expect(page).to have_content 'Repository Administrators'

      hpt = Hyrax::PermissionTemplate.where(source_id: collection.id).first
      hpta_count = Hyrax::PermissionTemplateAccess.where(
        permission_template_id: hpt.id,
        agent_type: "group",
        agent_id: "Repository Administrators",
        access: "manage"
      ).count
      expect(hpta_count).to eq 1
    end
  end
end
