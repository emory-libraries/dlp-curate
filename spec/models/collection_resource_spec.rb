# frozen_string_literal: true

require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe CollectionResource do
  subject(:collection) { described_class.new }

  it_behaves_like 'a Hyrax::PcdmCollection'

  it 'has abstracts' do
    expect { collection.abstract = ['lorem ipsum', 'a story about moomins'] }
      .to change { collection.abstract }
      .to contain_exactly 'lorem ipsum', 'a story about moomins'
  end

  it 'has a label' do
    expect { collection.label = 'one single label' }
      .to change { collection.label }
      .to eq 'one single label'
  end

  it 'has resource types' do
    expect { collection.resource_type = ['book', 'image'] }
      .to change { collection.resource_type }
      .to contain_exactly 'book', 'image'
  end

  it 'has rights notes' do
    expect { collection.rights_notes = ['secret', 'do not use'] }
      .to change { collection.rights_notes }
      .to contain_exactly 'secret', 'do not use'
  end

  it 'has sources' do
    expect { collection.source = ['first', 'second'] }
      .to change { collection.source }
      .to contain_exactly 'first', 'second'
  end

  %w[
    abstract
    administrative_unit
    alt_title
    contact_information
    contributors
    creator
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
  ].each do |attr|
    include_examples('checks model for new attribute response', attr)
  end
end
