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

    expect(page).to have_content 'Description/Abstract (abstract)'
    expect(page).to have_content 'Access Restrictions (access_restriction_notes)'
    expect(page).to have_content 'Administrative Unit (administrative_unit)'
    expect(page).to have_content 'Author Notes (author_notes)'
    expect(page).to have_content 'Conference Dates (conference_dates)'
    expect(page).to have_content 'Event/Conference Name (conference_name)'
    expect(page).to have_content 'Contact Information (contact_information)'
    expect(page).to have_content 'Genre (content_genres)'
    expect(page).to have_content 'Format (content_type)'
    expect(page).to have_content 'Audio'
    expect(page).to have_content 'Copyright Date (copyright_date)'
    expect(page).to have_content 'Creator (creator)'
    expect(page).to have_content 'Data Classification (data_classifications)'
    expect(page).to have_content 'Data Collection Dates (data_collection_dates)'
    expect(page).to have_content 'Data Source Notes (data_source_notes)'
    expect(page).to have_content 'Date Created (date_created)'
    expect(page).to have_content 'Date Digitized (date_digitized)'
    expect(page).to have_content 'Date Published / Issued (date_issued)'
    expect(page).to have_content 'Data Producer (data_producers)'
    expect(page).to have_content 'Edition (edition)'
    # Not indexed in solr
    # expect(page).to have_content 'extent (Extent/Dimensions)'
    expect(page).to have_content 'A very large extent'
    expect(page).to have_content 'Final Published Version (final_published_versions)'
    expect(page).to have_content 'Geographic Level for Dataset (geographic_unit)'
    expect(page).to have_content 'Grant/Funding Agency (grant_agencies)'
    # Not indexed in solr
    # expect(page).to have_content 'grant_information (Grant/Funding Information)'
    expect(page).to have_content 'Library (holding_repository)'
    expect(page).to have_content 'Internal Rights Note (internal_rights_note)'
    expect(page).to have_content 'ISBN (isbn)'
    expect(page).to have_content 'ISSN (issn)'
    expect(page).to have_content 'Emory ARK (emory_ark)'
    expect(page).to have_content 'Other Identifiers (other_identifiers)'
    expect(page).to have_content 'Legacy Rights Data (legacy_rights)'
    expect(page).to have_content 'Call Number (local_call_number)'
    expect(page).to have_content 'End Page (page_range_end)'
    expect(page).to have_content 'Start Page (page_range_start)'
    expect(page).to have_content 'Title of Parent Work (parent_title)'
    expect(page).to have_content 'Place of Publication/Production (place_of_production)'
    expect(page).to have_content 'Primary Language (primary_language)'
    expect(page).to have_content 'Persistent URL (primary_repository_ID)'
    expect(page).to have_content 'Version of Publication (publisher_version)'
    expect(page).to have_content 'Re-Use License (re_use_license)'
    expect(page).to have_content 'Related Datasets (related_datasets)'
    expect(page).to have_content 'Related Material (related_material_notes)'
    expect(page).to have_content 'Related publications'
    expect(page).to have_content 'Rights Documentation URL (rights_documentation)'
    expect(page).to have_content 'Rights Holder (rights_holders)'
    expect(page).to have_content 'Rights Statement - Controlled (rights_statement)'
    expect(page).to have_content 'In Copyright'
    expect(page).to have_content 'Rights Statement (emory_rights_statements)'
    expect(page).to have_content 'This is my rights statement text'
    # What is now the emory_rights_statement previously matched against the same text as rights_statement above.
    # expect(page).to have_content 'emory_rights_statement (Rights Statement)'
    expect(page).to have_content 'This is my rights statement text'
    expect(page).to have_content 'Scheduled Rights Review Date (scheduled_rights_review)'
    expect(page).to have_content 'Scheduled Rights Review Note (scheduled_rights_review_note)'
    expect(page).to have_content 'Sensitive/Objectionable Material (sensitive_material)'
    expect(page).to have_content 'Sensitive/Objectionable Material Note (sensitive_material_note)'
    expect(page).to have_content 'Sponsor (sponsor)'
    expect(page).to have_content 'Staff Note (staff_notes)'
    expect(page).to have_content 'Subject - Geographic Locations (subject_geo)'
    expect(page).to have_content 'Subject - Names (subject_names)'
    expect(page).to have_content 'Subject - Time Periods (subject_time_periods)'
    expect(page).to have_content 'Subject - Topics (subject_topics)'
    expect(page).to have_content 'System of Record ID (system_of_record_ID)'
    expect(page).to have_content 'Technical Note (technical_note)'
    expect(page).to have_content 'Title (title)'
    expect(page).to have_content 'Transfer Engineer (transfer_engineer)'
    expect(page).to have_content 'Volume (volume)'
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
      expect(page).to have_content('Notifications')
    end

    context 'when preservation_event has no failures' do
      it 'displays the right message' do
        visit "/concern/curate_generic_works/#{work.id}"
        expect(page).to have_content('No Event failures noted.')
      end
    end

    context 'when preservation_event has failures' do
      let(:work) do
        CurateGenericWork.create(
          title:                         ['foo'],
          depositor:                     'user1',
          preservation_event_attributes: [
            { 'event_type' => 'Yackety',
              'event_start' => DateTime.current,
              'outcome' => 'Failure',
              'event_details' => "Smackety",
              'software_version' => 'FITS v1.5.0',
              'initiating_user' => "10" }
          ]
        )
      end

      it 'displays the right message' do
        visit "/concern/curate_generic_works/#{work.id}"
        expect(page).to have_content('One or more recent events failed for this object:')
      end

      it 'displays the right details and dates' do
        visit "/concern/curate_generic_works/#{work.id}"
        expect(page).to have_content('Smackety')
        expect(page).to have_content(DateTime.current.strftime("%F"))
      end
    end

    context 'when no pwf is supplied' do
      let(:work) { CurateGenericWork.create(title: ['foo'], depositor: 'example') }

      it 'has no pwf information' do
        visit "/concern/curate_generic_works/#{work.id}"
        expect(page).to have_content('No information supplied').twice
      end
    end

    context 'when only ingest pwf is supplied' do
      let(:work) do
        CurateGenericWork.create(title: ['foo'], depositor: 'example', preservation_workflow_attributes: [{ "workflow_type" => "Ingest", "workflow_notes" => "Ingest notes" },
                                                                                                          { "workflow_type" => "Accession" }])
      end

      it 'has only ingest and no accession pwf information' do
        visit "/concern/curate_generic_works/#{work.id}"
        expect(page).to have_content('Ingest')
        expect(page).to have_content('Ingest notes')
        expect(page).to have_content('No information supplied').once
      end
    end

    context 'when both pwf are supplied' do
      let(:work) do
        CurateGenericWork.create(title: ['foo'], depositor: 'example', preservation_workflow_attributes: [{ "workflow_type" => "Ingest", "workflow_rights_basis_date" => "02/02/2012" },
                                                                                                          { "workflow_type" => "Accession", "workflow_rights_basis_note" => "Accession notes" }])
      end

      it 'has both pwf information' do
        visit "/concern/curate_generic_works/#{work.id}"
        expect(page).to have_content('Ingest')
        expect(page).to have_content('Accession')
        expect(page).to have_content('Accession notes')
      end
    end
  end
end
