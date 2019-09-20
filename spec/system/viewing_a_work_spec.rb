# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing the importer guide', type: :system do
  let(:admin_user) { FactoryBot.build(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata) }
  before do
    login_as admin_user
    work.save!
    work.reload
  end

  it 'has all the labels' do
    visit "/concern/curate_generic_works/#{work.id}"

    expect(page).to have_content 'abstract (Description/Abstract)'
    expect(page).to have_content 'access_restriction_notes (Access Restriction)'
    expect(page).to have_content 'administrative_unit (Administrative Unit)'
    expect(page).to have_content 'author_notes (Author Note)'
    # Not indexed in solr
    # expect(page).to have_content 'conference_dates (Conference Dates)'
    expect(page).to have_content 'conference_names (Conference/Meeting Name)'
    expect(page).to have_content 'contact_information (Contact Information)'
    expect(page).to have_content 'content_genres (Content Genre)'
    expect(page).to have_content 'content_type (Content Type)'
    expect(page).to have_content 'Audio'
    expect(page).to have_content 'copyright_date (Copyright Date)'
    expect(page).to have_content 'creator (Creator)'
    expect(page).to have_content 'data_classifications (Data Classification)'
    expect(page).to have_content 'data_collection_dates (Data Collection Date)'
    expect(page).to have_content 'data_source_notes (Data Sources Note)'
    expect(page).to have_content 'date_created (Date Created)'
    expect(page).to have_content 'date_digitized (Date Digitized)'
    expect(page).to have_content 'date_issued (Date Issued)'
    expect(page).to have_content 'data_producers (Data Producer)'
    # Not indexed in solr
    # expect(page).to have_content 'extent (Extent/Dimensions)'
    expect(page).to have_content 'A very large extent'
    # Not indexed in solr
    # expect(page).to have_content 'final_published_versions (Final Published Version)'
    expect(page).to have_content 'geographic_unit (Geographic Level For Dataset)'
    expect(page).to have_content 'grant_agencies (Grant/Funding Agency)'
    # Not indexed in solr
    # expect(page).to have_content 'grant_information (Grant/Funding Information)'
    expect(page).to have_content 'holding_repository (Library)'
    expect(page).to have_content 'internal_rights_note (Internal Rights Note)'
    expect(page).to have_content 'isbn (ISBN)'
    expect(page).to have_content 'issn (ISSN)'
    expect(page).to have_content 'emory_ark (Legacy ARK ID)'
    expect(page).to have_content 'other_identifiers (Other Identifier)'
    expect(page).to have_content 'legacy_rights (Legacy Rights Data)'
    expect(page).to have_content 'local_call_number (Call Number)'
    # Not indexed in solr
    # expect(page).to have_content 'page_range_end (Page Range - End)'
    # Not indexed in solr
    # expect(page).to have_content 'page_range_start (Page Range - Start)'
    expect(page).to have_content 'parent_title (Title of Parent Work)'
    # Not indexed in solr
    # expect(page).to have_content 'place_of_production (Place of Publication/Production)'
    expect(page).to have_content 'primary_language (Primary Language)'
    # Not indexed in solr
    # expect(page).to have_content 'primary_repository_ID (Persistent URL)'
    expect(page).to have_content 'publisher_version (Version of Publication)'
    # Not indexed in solr
    # expect(page).to have_content 're_use_license (Re-Use License)'
    # expect(page).to have_content 'related_datasets (Related Datasets)'
    expect(page).to have_content 'related_material_notes (Related Material)'
    # Not indexed in solr
    # expect(page).to have_content 'rights_documentation (Rights Documentation URL)'
    # Not indexed in solr
    # expect(page).to have_content 'rights_holders (Rights Holder)'
    expect(page).to have_content 'rights_statement (Rights Statement - Controlled)'
    expect(page).to have_content 'In Copyright'
    expect(page).to have_content 'emory_rights_statements (Rights Statement)'
    expect(page).to have_content 'This is my rights statement text'
    # What is now the emory_rights_statement previously matched against the same text as rights_statement above.
    # expect(page).to have_content 'emory_rights_statement (Rights Statement)'
    expect(page).to have_content 'This is my rights statement text'
    expect(page).to have_content 'scheduled_rights_review (Scheduled Rights Review Date)'
    expect(page).to have_content 'scheduled_rights_review_note (Scheduled Rights Review Note)'
    expect(page).to have_content 'sensitive_material (Sensitive/Objectionable Material)'
    expect(page).to have_content 'sensitive_material_note (Sensitive/Objectionable Material Note)'
    expect(page).to have_content 'staff_notes (Staff Note)'
    expect(page).to have_content 'subject_geo (Subject - Geographic Location)'
    expect(page).to have_content 'subject_names (Subject - Name)'
    expect(page).to have_content 'subject_time_periods (Subject - Time Period)'
    expect(page).to have_content 'subject_topics (Subject - Topic)'
    expect(page).to have_content 'system_of_record_ID (System Of Record ID)'
    expect(page).to have_content 'technical_note (Technical Note)'
    expect(page).to have_content 'title (Title)'
    expect(page).to have_content 'transfer_engineer (Transfer Engineer)'
    # preservation workflow
    expect(page).to have_content 'Workflow Type'
    expect(page).to have_content 'Workflow Notes'
    expect(page).to have_content 'Workflow Rights Basis'
    expect(page).to have_content 'Workflow Rights Basis Note'
    expect(page).to have_content 'Workflow Rights Basis Date'
    expect(page).to have_content 'Workflow Rights Basis Reviewer'
    expect(page).to have_content 'Workflow Rights Basis Uri'
  end
end
