# frozen_string_literal: true

require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe GenericWorkResource do
  subject(:work) { described_class.new }

  it_behaves_like 'a Hyrax::Work'

  it 'has resource types' do
    expect { work.resource_type = ['book', 'image'] }
      .to change { work.resource_type }
      .to contain_exactly 'book', 'image'
  end

  it 'has rights notes' do
    expect { work.rights_notes = ['secret', 'do not use'] }
      .to change { work.rights_notes }
      .to contain_exactly 'secret', 'do not use'
  end

  it 'has sources' do
    expect { work.source = ['first', 'second'] }
      .to change { work.source }
      .to contain_exactly 'first', 'second'
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
    preservation_workflow_terms
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
