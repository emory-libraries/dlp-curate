# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'viewing a the event details page for a work', type: :system, clean: true do
  include PreservationEvents
  let(:admin_user) { FactoryBot.create(:admin) }
  let(:work) { CurateGenericWork.where(deduplication_key: 'MSS1218_B071_I205').first }
  let(:csv) { fixture_path + '/preservation_workflows.csv' }
  let(:pe) do
    {
      'type' => 'Validation',
      'start' => DateTime.current,
      'outcome' => 'Success',
      'details' => 'Example details',
      'software_version' => 'Curate v.1',
      'user' => 'userexample'
    }
  end
  before do
    CurateGenericWork.create(title: ['Example title'], deduplication_key: 'MSS1218_B071_I205')
    login_as admin_user
    PreservationWorkflowImporter.import(csv)
    create_preservation_event(work, pe)
    work.save!
    work.reload
    visit "/concern/curate_generic_works/#{work.id}/event_details?locale=en"
  end

  it "loads the page with a main title and details" do
    expect(body).to have_content('View Preservation Details')
    expect(body).to have_content('Migrated to Cor repository from Extensis Portfolio DAMS')
    expect(body).to have_content('Scholarly Communications Office')
    expect(body).to have_content("This is a sample note. This field isn't always populated.")
    table_headers = all('#fs-preservation-event-table th').map(&:text)
    expect(table_headers).to eq(["Event", "Timestamp", "Outcome", "Detail", "User", "Software"])
    table_values = all('#fs-preservation-event-table td').map(&:text)
    preservation_event = work.preservation_event.first
    expect(table_values).to eq(
      [
        'Validation',
        "Start: #{preservation_event.event_start.first} End: #{preservation_event.event_end.first}",
        'Success',
        'Example details',
        'userexample',
        'Curate v.1'
      ]
    )
  end
end
