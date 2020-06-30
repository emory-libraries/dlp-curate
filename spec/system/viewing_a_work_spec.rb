# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing the importer guide', type: :system, clean: true do
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata, user: admin_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:user_work) { FactoryBot.build(:public_generic_work, user: user) }
  let(:work_url) { "/concern/curate_generic_works/#{work.id}" }
  before do
    login_as admin_user
    work.save!
    work.reload
    user_work.save!
    user_work.reload
  end

  context 'page metadata labels' do
    before { visit work_url }

    include_examples "check_page_for_multiple_text",
      [
        'abstract (Description/Abstract)',
        'access_restriction_notes (Access Restriction)',
        'administrative_unit (Administrative Unit)',
        'author_notes (Author Note)',
        'conference_dates (Conference Dates)',
        'conference_names (Conference/Meeting Name)',
        'contact_information (Contact Information)',
        'content_genres (Content Genre)',
        'content_type (Content Type)',
        'Audio',
        'copyright_date (Copyright Date)',
        'creator (Creator)',
        'data_classifications (Data Classification)',
        'data_collection_dates (Data Collection Date)',
        'data_source_notes (Data Sources Note)',
        'date_created (Date Created)',
        'date_digitized (Date Digitized)',
        'date_issued (Date Issued)',
        'data_producers (Data Producer)',
        'Edition',
        'A very large extent',
        'final_published_versions (Final Published Version)',
        'geographic_unit (Geographic Level For Dataset)',
        'grant_agencies (Grant/Funding Agency)',
        'holding_repository (Library)',
        'internal_rights_note (Internal Rights Note)',
        'isbn (ISBN)',
        'issn (ISSN)',
        'emory_ark (Legacy ARK ID)',
        'other_identifiers (Other Identifier)',
        'legacy_rights (Legacy Rights Data)',
        'local_call_number (Call Number)',
        'page_range_end (Page Range - End)',
        'page_range_start (Page Range - Start)',
        'parent_title (Title of Parent Work)',
        'place_of_production (Place of Publication/Production)',
        'primary_language (Primary Language)',
        'primary_repository_id (Persistent URL)',
        'publisher_version (Version of Publication)',
        're_use_license (Re-Use License)',
        'related_datasets (Related Dataset)',
        'related_material_notes (Related Material)',
        'Related publications',
        'rights_documentation (Rights Documentation URL)',
        'rights_holders (Rights Holder)',
        'rights_statement (Rights Statement - Controlled)',
        'In Copyright',
        'emory_rights_statements (Rights Statement)',
        'This is my rights statement text',
        'This is my rights statement text',
        'scheduled_rights_review (Scheduled Rights Review Date)',
        'scheduled_rights_review_note (Scheduled Rights Review Note)',
        'sensitive_material (Sensitive/Objectionable Material)',
        'sensitive_material_note (Sensitive/Objectionable Material Note)',
        'Sponsor',
        'staff_notes (Staff Note)',
        'subject_geo (Subject - Geographic Location)',
        'subject_names (Subject - Name)',
        'subject_time_periods (Subject - Time Period)',
        'subject_topics (Subject - Topic)',
        'system_of_record_ID (System Of Record ID)',
        'technical_note (Technical Note)',
        'title (Title)',
        'transfer_engineer (Transfer Engineer)',
        'Volume'
      ],
      'has the right labels'

    # Not indexed in solr 'extent (Extent/Dimensions)', 'grant_information (Grant/Funding Information)'

    # What is now the emory_rights_statement previously matched against the same text as rights_statement above: 'emory_rights_statement (Rights Statement)'
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
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Public')
      end
    end

    context 'emory high download work (authenticated)' do
      let(:work) { FactoryBot.create(:emory_high_work) }

      it "has emory high download visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Emory High Download')
      end
    end

    context 'emory low download work (emory_low)' do
      let(:work) { FactoryBot.create(:emory_low_work) }

      it "has emory low download visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Emory Low Download')
      end
    end

    context 'public low view work (low_res)' do
      let(:work) { FactoryBot.create(:public_low_work) }

      it "has public low view visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Public Low View')
      end
    end

    context 'private work (restricted)' do
      let(:work) { FactoryBot.create(:private_work) }

      it "has private visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Private')
      end
    end

    context 'rose high download (rose_high)' do
      let(:work) { FactoryBot.create(:rose_high_work) }

      it "has rose high download visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Rose High View')
      end
    end
  end

  describe 'preservation status block' do
    let(:work) { CurateGenericWork.create(title: ['foo'], depositor: 'example') }

    context 'normal state' do
      before { visit work_url }

      include_examples "check_page_for_multiple_text",
        ['Preservation Status', 'Date Uploaded', 'Date Modified', 'Depositor', 'Notifications'],
        'has status block with details'
    end

    context 'when preservation_event has no failures' do
      it 'displays the right message' do
        visit work_url
        expect(page).to have_content('No Event failures noted.')
      end
    end

    context 'when preservation_event has failures' do
      before do
        work.preservation_event_attributes = [
          { 'event_type' => 'Yackety',
            'event_start' => DateTime.current,
            'outcome' => 'Failure',
            'event_details' => "Smackety",
            'software_version' => 'FITS v1.5.0',
            'initiating_user' => "10" }
        ]
        work.save!
        visit work_url
      end

      it 'displays the right message' do
        expect(page).to have_content('One or more recent events failed for this object:')
      end

      include_examples "check_page_for_multiple_text",
        ['Smackety', DateTime.current.strftime("%F")],
        'displays the right details and dates'
    end

    context 'when no pwf is supplied' do
      it 'has no pwf information' do
        visit work_url

        expect(page).to have_content('No information supplied').twice
      end
    end

    context 'when only ingest pwf is supplied' do
      before do
        work.preservation_workflow_attributes = [
          { "workflow_type" => "Ingest", "workflow_notes" => "Ingest notes" },
          { "workflow_type" => "Accession" }
        ]
        work.save!
        visit work_url
      end

      it 'has no accession pwf information' do
        expect(page).to have_content('No information supplied').once
      end
      include_examples "check_page_for_multiple_text",
        ['Ingest', 'Ingest notes'],
        'has only ingest information'
    end

    context 'when both pwf are supplied' do
      before do
        work.preservation_workflow_attributes = [
          { "workflow_type" => "Ingest", "workflow_rights_basis_date" => "02/02/2012" },
          { "workflow_type" => "Accession", "workflow_rights_basis_note" => "Accession notes" }
        ]
        work.save!
        visit work_url
      end

      include_examples "check_page_for_multiple_text",
        ['Ingest', 'Accession', 'Accession notes'],
        'has both pwf information'
    end

    context 'more details link' do
      it 'provides a link to the view more details page' do
        visit work_url

        expect(page).to have_link('More Event Detail')
      end
    end
  end
end
