# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionResourceIndexer do
  let(:solr_document) { described_class.new(resource:).to_solr }
  let(:resource) do
    CollectionResource.new(
      id:                    'collection-1',
      title:                 ['Chester W. Topp collection of Victorian yellowbacks and paperbacks'],
      contact_information:   'Rose Library Woodruff Library Emory University',
      institution:           'Emory University',
      primary_language:      'English',
      finding_aid_link:      'https://findingaids.library.emory.edu/documents/topp',
      local_call_number:     'MSS 1234',
      internal_rights_note:  'Internal note',
      rights_documentation:  'https://example.com/rights',
      sensitive_material:    'No',
      system_of_record_ID:   'alma:990012345',
      primary_repository_ID: 'repo-1'
    )
  end

  # SolrDocumentAccessors (and Lux) read the field names the AF Collection indexer used.
  describe 'single-valued descriptive fields' do
    it 'indexes them under the AF field names as well' do
      expect(solr_document).to include(
        'contact_information_tesim' => 'Rose Library Woodruff Library Emory University',
        'institution_tesim' => 'Emory University',
        'primary_language_tesim' => 'English',
        'local_call_number_tesim' => 'MSS 1234',
        'internal_rights_note_tesim' => 'Internal note',
        'rights_documentation_tesim' => 'https://example.com/rights',
        'sensitive_material_tesim' => 'No',
        'system_of_record_ID_tesim' => 'alma:990012345',
        'primary_repository_ID_tesim' => 'repo-1',
        'finding_aid_link_ssm' => 'https://findingaids.library.emory.edu/documents/topp'
      )
    end

    it 'keeps the existing Valkyrie field names' do
      expect(solr_document).to include('contact_information_tesi', 'institution_ssi', 'primary_language_si', 'finding_aid_link_tesi')
    end

    it 'is readable through SolrDocument' do
      # Solr returns multivalued (_tesim/_ssm) fields as arrays.
      document = SolrDocument.new(solr_document.to_h { |k, v| [k, k.end_with?('_tesim', '_ssm') ? Array(v) : v] })

      expect(document.contact_information).to eq ['Rose Library Woodruff Library Emory University']
      expect(document.institution).to eq ['Emory University']
      expect(document.primary_language).to eq ['English']
      expect(document.finding_aid_link).to eq ['https://findingaids.library.emory.edu/documents/topp']
    end
  end
end
