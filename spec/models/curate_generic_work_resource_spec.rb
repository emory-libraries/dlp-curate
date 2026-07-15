# frozen_string_literal: true

require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe CurateGenericWorkResource do
  subject(:work) { described_class.new }

  it_behaves_like 'a Hyrax::Work'

  describe 'class hierarchy' do
    it 'inherits from Hyrax::Work' do
      expect(described_class).to be < Hyrax::Work
    end
  end

  describe 'schemas' do
    it 'includes emory_basic_metadata schema' do
      expect(described_class.fields).to include(:holding_repository, :emory_ark, :institution)
    end

    it 'includes curate_generic_work_resource schema' do
      expect(described_class.fields).to include(:content_type, :date_issued, :deduplication_key)
    end
  end

  describe 'PreservationEvents' do
    it 'includes PreservationEvents concern' do
      expect(described_class.ancestors).to include(PreservationEvents)
    end

    it 'responds to create_preservation_event' do
      expect(work).to respond_to(:create_preservation_event)
    end
  end

  describe '#preservation_event' do
    let(:preservation_event) do
      PreservationEventResource.new(
        event_id:         'test-event-id-123',
        event_type:       'Fixity Check',
        initiating_user:  'admin@example.com',
        event_start:      '2024-01-01',
        event_end:        '2024-01-01',
        outcome:          'Success',
        software_version: 'dlp-curate v1.0',
        event_details:    'Fixity check passed'
      )
    end

    it 'accepts PreservationEventResource' do
      work.preservation_event += [preservation_event]
      expect(work.preservation_event).to contain_exactly(preservation_event)
    end

    it 'defaults to an empty set' do
      expect(work.preservation_event).to be_empty
    end
  end

  %w[
    abstract
    access_restriction_notes
    administrative_unit
    alt_title
    author_notes
    conference_dates
    conference_name
    contact_information
    content_genres
    content_type
    contributors
    copyright_date
    creator
    data_classifications
    data_collection_dates
    data_producers
    data_source_notes
    date_digitized
    date_issued
    deduplication_key
    edition
    emory_ark
    emory_rights_statements
    extent
    final_published_versions
    geographic_unit
    grant_agencies
    grant_information
    holding_repository
    institution
    internal_rights_note
    isbn
    issn
    issue
    keywords
    legacy_rights
    local_call_number
    notes
    other_identifiers
    page_range_end
    page_range_start
    parent_title
    place_of_production
    primary_language
    primary_repository_ID
    publisher
    publisher_version
    re_use_license
    related_datasets
    related_material_notes
    related_publications
    rights_documentation
    rights_holders
    rights_statement
    scheduled_rights_review
    scheduled_rights_review_note
    sensitive_material
    sensitive_material_note
    series_title
    source_collection_id
    sponsor
    staff_notes
    subject_geo
    subject_names
    subject_time_periods
    subject_topics
    sublocation
    system_of_record_ID
    table_of_contents
    technical_note
    transfer_engineer
    uniform_title
    volume
  ].each do |attr|
    include_examples('checks model for new attribute response', attr)
  end
end
