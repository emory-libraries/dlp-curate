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

  context 'elements that should not be on page' do
    before { visit work_url }

    it 'does not show Citations button' do
      expect(page).not_to have_css('button', text: 'Citations:')
    end

    it 'does not show social media buttons' do
      social_media = page.find_all('a.resp-sharing-button__link')

      expect(social_media.size).to eq(0)
    end

    it 'does not show feature button' do
      expect(page).not_to have_link('Feature')
    end
  end

  context 'page metadata labels' do
    before { visit work_url }

    include_examples "check_page_for_multiple_text",
      [
        'Description/Abstract (abstract)',
        'Access Restrictions (access_restriction_notes)',
        'Administrative Unit (administrative_unit)',
        'Author Notes (author_notes)',
        'Conference Dates (conference_dates)',
        'Event/Conference Name (conference_name)',
        'Contact Information (contact_information)',
        'Genre (content_genres)',
        'Format (content_type)',
        'Audio',
        'Copyright Date (copyright_date)',
        'Creator (creator)',
        'Data Classification (data_classifications)',
        'Data Collection Dates (data_collection_dates)',
        'Data Source Notes (data_source_notes)',
        'Date Created (date_created)',
        'Date Digitized (date_digitized)',
        'Date Published / Issued (date_issued)',
        'Data Producer (data_producers)',
        'Edition (edition)',
        'A very large extent',
        'Final Published Version (final_published_versions)',
        'Geographic Level for Dataset (geographic_unit)',
        'Grant/Funding Agency (grant_agencies)',
        'Library (holding_repository)',
        'Internal Rights Note (internal_rights_note)',
        'ISBN (isbn)',
        'ISSN (issn)',
        'Emory ARK (emory_ark)',
        'Other Identifiers (other_identifiers)',
        'Legacy Rights Data (legacy_rights)',
        'Call Number (local_call_number)',
        'End Page (page_range_end)',
        'Start Page (page_range_start)',
        'Title of Parent Work (parent_title)',
        'Place of Publication/Production (place_of_production)',
        'Primary Language (primary_language)',
        'Persistent URL (primary_repository_ID)',
        'Version of Publication (publisher_version)',
        'Re-Use License (re_use_license)',
        'Related Datasets (related_datasets)',
        'Related Material (related_material_notes)',
        'Related Publications (related_publications)',
        'Rights Documentation URL (rights_documentation)',
        'Rights Holder (rights_holders)',
        'Rights Statement - Controlled (rights_statement)',
        'In Copyright',
        'Rights Statement (emory_rights_statements)',
        'This is my rights statement text',
        'Scheduled Rights Review Date (scheduled_rights_review)',
        'Scheduled Rights Review Note (scheduled_rights_review_note)',
        'Sensitive/Objectionable Material (sensitive_material)',
        'Sensitive/Objectionable Material Note (sensitive_material_note)',
        'Sponsor (sponsor)',
        'Staff Note (staff_notes)',
        'Subject - Geographic Locations (subject_geo)',
        'Subject - Names (subject_names)',
        'Subject - Time Periods (subject_time_periods)',
        'Subject - Topics (subject_topics)',
        'System of Record ID (system_of_record_ID)',
        'Technical Note (technical_note)',
        'Title (title)',
        'Transfer Engineer (transfer_engineer)',
        'Volume (volume)'
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

    it 'has delete selected and add to collections buttons' do
      visit "dashboard/works"
      find("input[type='checkbox'][id='check_all']").set(true)
      expect(page).to have_selector("input[value='delete_all']", visible: false)
      expect(page).to have_css('button', text: 'Add to collection')
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

    it 'does not have a batch upload link on the works dashboard' do
      visit "/dashboard/works"
      expect(page).not_to have_link(href: /batch/)
    end

    it 'does not have delete selected and add to collections buttons' do
      visit "dashboard/works"
      find("input[type='checkbox'][id='check_all']").set(true)
      expect(page).not_to have_selector("input[value='delete_all']", visible: false)
      expect(page).not_to have_css('button', text: 'Add to collection')
    end

    context 'viewer role' do
      let(:user) do
        User.create(
                uid:          'brianbboys1967',
                ppid:         'P0000001',
                display_name: 'Brian Wilson'
              )
      end

      it 'has no Add new work button' do
        user.roles = [Role.find_or_create_by(name: 'rose_viewer')]
        user.save
        visit "dashboard/works"

        expect(page).not_to have_link "Add new work"

        visit "dashboard/my/works"

        expect(page).not_to have_link "Add new work"
      end
    end
  end

  describe 'object visibility', :clean do
    context 'public work (open)' do
      let(:work) { FactoryBot.create(:public_generic_work) }

      it "has public visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Public')
        expect(badge_text(page)).to eq('Public')
      end
    end

    context 'emory high download work (authenticated)' do
      let(:work) { FactoryBot.create(:emory_high_work) }

      it "has emory high download visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Emory High Download')
        expect(badge_text(page)).to eq('Emory High Download')
      end
    end

    context 'emory low download work (emory_low)' do
      let(:work) { FactoryBot.create(:emory_low_work) }

      it "has emory low download visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Emory Low Download')
        expect(badge_text(page)).to eq('Emory Low Download')
      end
    end

    context 'public low view work (low_res)' do
      let(:work) { FactoryBot.create(:public_low_work) }

      it "has public low view visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Public Low View')
        expect(badge_text(page)).to eq('Public Low View')
      end
    end

    context 'private work (restricted)' do
      let(:work) { FactoryBot.create(:private_work) }

      it "has private visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Private')
        expect(badge_text(page)).to eq('Private')
      end
    end

    context 'rose high download (rose_high)' do
      let(:work) { FactoryBot.create(:rose_high_work) }

      it "has rose high download visibility metadata" do
        visit(work_url)

        expect(page).to have_css("#visibility", text: 'Rose High View')
        expect(badge_text(page)).to eq('Rose High View')
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

      context 'top metadata block' do
        it 'has no listing of Preservation event' do
          within 'dl.work-show.curate_generic_work' do
            pres_event_attributes = find_all('li.attribute.attribute-preservation_event')

            expect(page).not_to have_content('Preservation event')
            expect(pres_event_attributes.size).to eq(0)
          end
        end
      end
    end

    context 'when no pwf is supplied' do
      it 'has no pwf information' do
        visit work_url

        expect(page).to have_content('No information supplied').exactly(4)
      end
    end

    context 'when only one pwf is supplied' do
      before do
        work.preservation_workflow_attributes = [
          { "workflow_type" => "Ingest", "workflow_notes" => "Ingest notes" },
          { "workflow_type" => "Accession" }
        ]
        work.save!
        visit work_url
      end

      it 'has no accession pwf information' do
        expect(page).to have_content('No information supplied').thrice
      end
      include_examples "check_page_for_multiple_text",
        ['Ingest', 'Ingest notes'],
        'has only ingest information'
    end

    context 'when two pwfs are supplied' do
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
        'has two pwfs information'
    end

    context 'when all pwfs are supplied' do
      before do
        work.preservation_workflow_attributes = [
          { "workflow_type" => "Ingest", "workflow_rights_basis_date" => "02/02/2012", "workflow_rights_basis_note" => "Ingest notes" },
          { "workflow_type" => "Accession", "workflow_rights_basis_note" => "Accession notes" },
          { "workflow_type" => "Deletion", "workflow_rights_basis_note" => "Deletion notes" },
          { "workflow_type" => "Decommission", "workflow_rights_basis_note" => "Decommission notes" }
        ]
        work.save!
        visit work_url
      end

      include_examples "check_page_for_multiple_text",
        ['Ingest', 'Ingest notes', 'Accession', 'Accession notes', 'Deletion notes', 'Decommission notes'],
        'has all four pwf information'

      it 'will not have the no info warning' do
        expect(page).to have_no_content('No information supplied')
      end

      context 'top metadata block' do
        it 'has no listing of Preservation workflow terms' do
          within 'dl.work-show.curate_generic_work' do
            pres_event_attributes = find_all('li.attribute.attribute-preservation_workflow_terms')

            expect(page).not_to have_content('Preservation workflow terms')
            expect(pres_event_attributes.size).to eq(0)
          end
        end
      end
    end

    context 'more details link' do
      it 'provides a link to the view more details page' do
        visit work_url

        expect(page).to have_link('More Event Detail')
      end
    end
  end

  describe 'object relations' do
    context 'when source collection is present' do
      let(:work) { FactoryBot.create(:public_generic_work) }
      let(:collection) { FactoryBot.create(:collection_lw, title: ['Collection test']) }
      before do
        work.source_collection_id = collection.id
        work.save!
      end

      it 'shows source collection under relations section' do
        visit(work_url)

        expect(page).to have_link('Collection test')
      end
    end

    context 'when source collection is absent' do
      it 'does not show source collection details' do
        visit(work_url)

        expect(page).not_to have_link('Collection test')
      end
    end
  end

  describe 'viewing works using source collection facet' do
    context 'when source collection is present' do
      let(:work) { FactoryBot.create(:public_generic_work, title: ['SC test work']) }
      let(:work2) { FactoryBot.create(:public_generic_work, title: ['SC test work2']) }
      let(:collection) { FactoryBot.create(:collection_lw, title: ['Collection test']) }
      before do
        work.source_collection_id = collection.id
        work.save!
      end

      it 'shows source collection in its dropdown facet' do
        visit("/dashboard/works")
        expect(page).to have_content(collection.title.first)
        click_link(collection.title.first)
        expect(page).to have_content('SC test work') # make sure work with source collection shows up in search result
        expect(page).not_to have_content('SC test work 2') # make sure work without source collection does not show up in search result
      end
    end

    context 'when source collection is absent' do
      it 'does not show source collection details' do
        visit("/dashboard/works")

        expect(page).not_to have_content('Source Collection') # make sure dropdown is not present
      end
    end
  end

  def badge_text(page)
    page.find_all('div.title-with-badges span').first.text
  end
end
