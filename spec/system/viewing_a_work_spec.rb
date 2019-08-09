# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing the importer guide', type: :system do
  let(:admin_user) { FactoryBot.build(:admin) }
  let(:work) { FactoryBot.build(:work_with_full_metadata) }
  before do
    login_as admin_user
    work.save!
  end

  it 'has all the labels' do
    visit "/concern/curate_generic_works/#{work.id}"

    expect(page).to have_content 'Description/Abstract'
    expect(page).to have_content 'Access Restrictions'
    expect(page).to have_content 'Administrative Unit'
    expect(page).to have_content 'Administrative Unit'
    expect(page).to have_content 'Author Notes'
    # Not indexed in solr
    # expect(page).to have_content 'Conference Dates'
    expect(page).to have_content 'Conference/Meeting Name'
    expect(page).to have_content 'Contact Information'
    expect(page).to have_content 'Genre'
    expect(page).to have_content 'Format'
    expect(page).to have_content 'Copyright Date'
    expect(page).to have_content 'Creator'
    expect(page).to have_content 'Data Classification'
    expect(page).to have_content 'Data Collection Dates'
    expect(page).to have_content 'Data Sources Note'
    expect(page).to have_content 'Date Created'
    expect(page).to have_content 'Date Digitized'
    expect(page).to have_content 'Date Issued'
    expect(page).to have_content 'Data Producer'
    # Not indexed in solr
    # expect(page).to have_content 'Extent/Dimensions'
    # Not indexed in solr
    # expect(page).to have_content 'Final Published Version'
    expect(page).to have_content 'Geographic Level For Dataset'
    expect(page).to have_content 'Grant/Funding Agency'
    # Not indexed in solr
    # expect(page).to have_content 'Grant/Funding Information'
    expect(page).to have_content 'Library'
    expect(page).to have_content 'Internal Rights Note'
    expect(page).to have_content 'ISBN'
    expect(page).to have_content 'ISSN'
    expect(page).to have_content 'Legacy ARK ID'
    expect(page).to have_content 'Other Identifiers'
    expect(page).to have_content 'Legacy Rights Data'
    expect(page).to have_content 'Call Number'
    # Not indexed in solr
    # expect(page).to have_content 'Page Range - End'
    # Not indexed in solr
    # expect(page).to have_content 'Page Range - Start'
    expect(page).to have_content 'Title of Parent Work'
    # Not indexed in sorl
    # expect(page).to have_content 'Place of Publication/Production'
    expect(page).to have_content 'Primary Language'
    # Not indexed in solr
    # expect(page).to have_content 'Persistent URL'
    expect(page).to have_content 'Version of Publication'
    # Not indexed in solr
    # expect(page).to have_content 'Re-Use License'
    # Not indexed in solr
    # expect(page).to have_content 'Related Datasets'
    expect(page).to have_content 'Related Material'
    # Not indexed in solr
    # expect(page).to have_content 'Rights Documentation URL'
    # Not indexed in solr
    # expect(page).to have_content 'Rights Holder'
    expect(page).to have_content 'Rights Statement - Controlled'
    expect(page).to have_content 'Rights Statement'
    expect(page).to have_content 'Scheduled Rights Review Date'
    expect(page).to have_content 'Scheduled Rights Review Note'
    expect(page).to have_content 'Sensitive/Objectionable Material'
    expect(page).to have_content 'Sensitive/Objectionable Material Note'
    expect(page).to have_content 'Staff Note'
    expect(page).to have_content 'Subject - Geographic Locations'
    expect(page).to have_content 'Subject - Names'
    expect(page).to have_content 'Subject - Time Periods'
    expect(page).to have_content 'Subject - Topics'
    expect(page).to have_content 'System Of Record ID'
    expect(page).to have_content 'Technical Note'
    expect(page).to have_content 'Title'
    expect(page).to have_content 'Transfer Engineer'
  end
end
