# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing the importer guide', type: :system, clean: true do
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, user: admin_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:user_work) { FactoryBot.build(:public_generic_work, user: user) }
  before do
    login_as admin_user
    work.save!
    work.reload
    user_work.save!
    user_work.reload
  end

  it 'has all the labels', clean: true do
    visit "/concern/curate_generic_works/#{work.id}"

    expect(page).to have_content 'abstract (Description/Abstract)'
    expect(page).to have_content 'access_restriction_notes (Access Restriction)'
    expect(page).to have_content 'administrative_unit (Administrative Unit)'
    expect(page).to have_content 'author_notes (Author Note)'
    expect(page).to have_content 'conference_dates (Conference Dates)'
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
    expect(page).to have_content 'Edition'
    # Not indexed in solr
    # expect(page).to have_content 'extent (Extent/Dimensions)'
    expect(page).to have_content 'A very large extent'
    expect(page).to have_content 'final_published_versions (Final Published Version)'
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
    expect(page).to have_content 'page_range_end (Page Range - End)'
    expect(page).to have_content 'page_range_start (Page Range - Start)'
    expect(page).to have_content 'parent_title (Title of Parent Work)'
    expect(page).to have_content 'place_of_production (Place of Publication/Production)'
    expect(page).to have_content 'primary_language (Primary Language)'
    expect(page).to have_content 'primary_repository_id (Persistent URL)'
    expect(page).to have_content 'publisher_version (Version of Publication)'
    expect(page).to have_content 're_use_license (Re-Use License)'
    expect(page).to have_content 'related_datasets (Related Dataset)'
    expect(page).to have_content 'related_material_notes (Related Material)'
    expect(page).to have_content 'Related publications'
    expect(page).to have_content 'rights_documentation (Rights Documentation URL)'
    expect(page).to have_content 'rights_holders (Rights Holder)'
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
    expect(page).to have_content 'Sponsor'
    expect(page).to have_content 'staff_notes (Staff Note)'
    expect(page).to have_content 'subject_geo (Subject - Geographic Location)'
    expect(page).to have_content 'subject_names (Subject - Name)'
    expect(page).to have_content 'subject_time_periods (Subject - Time Period)'
    expect(page).to have_content 'subject_topics (Subject - Topic)'
    expect(page).to have_content 'system_of_record_ID (System Of Record ID)'
    expect(page).to have_content 'technical_note (Technical Note)'
    expect(page).to have_content 'title (Title)'
    expect(page).to have_content 'transfer_engineer (Transfer Engineer)'
    expect(page).to have_content 'Volume'
    # preservation workflow
    expect(page).to have_content 'Workflow Type'
    expect(page).to have_content 'Workflow Notes'
    expect(page).to have_content 'Workflow Rights Basis'
    expect(page).to have_content 'Workflow Rights Basis Note'
    expect(page).to have_content 'Workflow Rights Basis Date'
    expect(page).to have_content 'Workflow Rights Basis Reviewer'
    expect(page).to have_content 'Workflow Rights Basis Uri'
  end

  context 'when logged in as an admin' do
    before do
      login_as admin_user
    end

    it 'has a delete button on the show page' do
      visit "/concern/curate_generic_works/#{user_work.id}"
      expect(page).to have_selector(:css, 'a[data-method="delete"]')
    end

    it 'has a delete action on the all works dashboard' do
      visit "/dashboard/works"
      expect(page).to have_selector(:css, 'a[data-method="delete"]')
    end

    it 'has a delete action on the my works dashboard' do
      visit "/dashboard/my/works"
      expect(page).to have_selector(:css, 'a[data-method="delete"]')
    end
  end

  context 'when logged in as a non-admin user' do
    before do
      login_as user
    end

    it 'does not have a delete button on the show page' do
      visit "/concern/curate_generic_works/#{user_work.id}"
      expect(page).not_to have_selector(:css, 'a[data-method="delete"]')
    end

    it 'does not have a delete action on the all works dashboard' do
      visit "/dashboard/works"
      expect(page).not_to have_selector(:css, 'a[data-method="delete"]')
    end

    it 'does not have a delete action on the my works dashboard' do
      visit "/dashboard/my/works"
      expect(page).not_to have_selector(:css, 'a[data-method="delete"]')
    end
  end

  describe 'object visibility', :clean do
    context 'public work (open)' do
      let(:work) { FactoryBot.create(:public_generic_work) }

      it "has public visibility metadata" do
        visit("/concern/curate_generic_works/#{work.id}")

        expect(page).to have_css("#visibility", text: 'Public')
      end
    end

    context 'emory high download work (authenticated)' do
      let(:work) { FactoryBot.create(:emory_high_work) }

      it "has emory high download visibility metadata" do
        visit("/concern/curate_generic_works/#{work.id}")

        expect(page).to have_css("#visibility", text: 'Emory High Download')
      end
    end

    context 'emory low download work (emory_low)' do
      let(:work) { FactoryBot.create(:emory_low_work) }

      it "has emory low download visibility metadata" do
        visit("/concern/curate_generic_works/#{work.id}")

        expect(page).to have_css("#visibility", text: 'Emory Low Download')
      end
    end

    context 'public low view work (low_res)' do
      let(:work) { FactoryBot.create(:public_low_work) }

      it "has public low view visibility metadata" do
        visit("/concern/curate_generic_works/#{work.id}")

        expect(page).to have_css("#visibility", text: 'Public Low View')
      end
    end

    context 'private work (restricted)' do
      let(:work) { FactoryBot.create(:private_work) }

      it "has private visibility metadata" do
        visit("/concern/curate_generic_works/#{work.id}")

        expect(page).to have_css("#visibility", text: 'Private')
      end
    end

    context 'rose high download (rose_high)' do
      let(:work) { FactoryBot.create(:rose_high_work) }

      it "has rose high download visibility metadata" do
        visit("/concern/curate_generic_works/#{work.id}")

        expect(page).to have_css("#visibility", text: 'Rose High View')
      end
    end
  end

  describe 'preservation status block' do
    it 'has status block with details' do
      visit "/concern/curate_generic_works/#{work.id}"
      expect(page).to have_content('Preservation Status')
      expect(page).to have_content('Date Uploaded')
      expect(page).to have_content('Date Modified')
      expect(page).to have_content('Depositor')
    end
  end
end
