# frozen_string_literal: true

require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe CollectionResourceForm do
  let(:change_set) { described_class.new(resource) }
  let(:resource)   { CollectionResource.new }

  it_behaves_like 'a Valkyrie::ChangeSet'

  it 'has the expected fields' do
    expected_fields = %w[
      abstract
      administrative_unit
      alt_title
      contact_information
      contributors
      deduplication_key
      deposit_collection_ids
      emory_ark
      finding_aid_link
      holding_repository
      institution
      internal_rights_note
      keywords
      local_call_number
      notes
      primary_language
      primary_repository_ID
      rights_documentation
      sensitive_material
      source_collection_id
      staff_notes
      subject_geo
      subject_names
      subject_time_periods
      subject_topics
      system_of_record_ID
    ]

    expect(change_set.fields.keys).to include(*expected_fields)
  end
end
