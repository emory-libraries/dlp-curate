# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurateGenericWorkResourceIndexer do
  let(:indexer) { described_class.new(resource:) }
  let(:solr_document) { indexer.to_solr }
  let(:resource) do
    r = CurateGenericWorkResource.new(attributes.except(:visibility))
    allow(r).to receive(:visibility).and_return(attributes[:visibility] || 'restricted')
    r
  end
  let(:attributes) do
    {
      title:      ['Test title'],
      creator:    ['Test creator'],
      visibility: 'open'
    }
  end

  before do
    allow(Hyrax.custom_queries).to receive(:find_child_file_sets).and_return([])
    allow(Hyrax.custom_queries).to receive(:find_parent_works).and_return([])
  end

  describe '#to_solr' do
    it 'returns a hash' do
      expect(solr_document).to be_a(Hash)
    end
  end

  describe 'sort and date fields' do
    context 'with a date_created' do
      let(:attributes) do
        {
          title:        ['Test title'],
          date_created: '1940-10-15',
          creator:      ['Some creator'],
          visibility:   'open'
        }
      end

      it 'indexes the year created' do
        expect(solr_document['year_created_isim']).to eq [1940]
      end

      it 'indexes year for lux' do
        expect(solr_document['year_for_lux_isim']).to eq [1940]
      end

      it 'indexes sort year' do
        expect(solr_document['year_for_lux_ssi']).to eq 1940
      end
    end

    context 'with a date_issued' do
      let(:attributes) do
        {
          title:       ['Test title'],
          date_issued: '1941-01-15',
          creator:     ['Some creator'],
          visibility:  'open'
        }
      end

      it 'indexes the year issued' do
        expect(solr_document['year_issued_isim']).to eq [1941]
      end

      it 'indexes year for lux' do
        expect(solr_document['year_for_lux_isim']).to eq [1941]
      end
    end

    context 'when both date_created and date_issued have the same year' do
      let(:attributes) do
        {
          title:        ['Test title'],
          date_created: '1940-10-15',
          date_issued:  '1940-11-15',
          creator:      ['Some creator'],
          visibility:   'open'
        }
      end

      it 'deduplicates the year fields' do
        expect(solr_document['year_for_lux_isim']).to eq [1940]
      end
    end

    context 'when date_created and date_issued have different years' do
      let(:attributes) do
        {
          title:        ['Test title'],
          date_created: '1940-10-15',
          date_issued:  '1941-01-15',
          creator:      ['Some creator'],
          visibility:   'open'
        }
      end

      it 'saves both years in order' do
        expect(solr_document['year_for_lux_isim']).to eq [1940, 1941]
      end
    end

    context 'when date fields are blank' do
      let(:attributes) { { title: ['Test title'], visibility: 'open' } }

      it 'does not index year_created' do
        expect(solr_document['year_created_isim']).to be_nil
      end

      it 'does not index year_for_lux' do
        expect(solr_document['year_for_lux_isim']).to be_nil
      end

      it 'does not index sort year' do
        expect(solr_document['year_for_lux_ssi']).to be_nil
      end
    end
  end

  describe 'sort title' do
    context 'with a standard title' do
      let(:attributes) { { title: ['Some title'], visibility: 'open' } }

      it 'indexes the title as-is' do
        expect(solr_document['title_ssort']).to eq 'Some title'
      end
    end

    context 'with a leading article' do
      let(:attributes) { { title: ['A title'], visibility: 'open' } }

      it 'strips the leading article' do
        expect(solr_document['title_ssort']).to eq 'title'
      end
    end

    context 'with leading "The"' do
      let(:attributes) { { title: ['The Great Work'], visibility: 'open' } }

      it 'strips the leading "The"' do
        expect(solr_document['title_ssort']).to eq 'Great Work'
      end
    end

    context 'with leading "An"' do
      let(:attributes) { { title: ['An Example'], visibility: 'open' } }

      it 'strips the leading "An"' do
        expect(solr_document['title_ssort']).to eq 'Example'
      end
    end
  end

  describe 'creator sort' do
    let(:attributes) do
      { title: ['Test'], creator: ['Jane Doe', 'John Doe'], visibility: 'open' }
    end

    it 'indexes the first creator' do
      expect(solr_document['creator_ssort']).to eq 'Jane Doe'
    end
  end

  describe 'visibility_group_ssi' do
    {
      'open' => 'Public',
      'low_res' => 'Public',
      'emory_low' => 'Log In Required',
      'authenticated' => 'Log In Required',
      'rose_high' => 'Reading Room Only'
    }.each do |visibility, group|
      context "when visibility is #{visibility}" do
        let(:attributes) { { title: ['Test'], visibility: } }

        it "returns #{group}" do
          expect(solr_document['visibility_group_ssi']).to eq group
        end
      end
    end
  end

  describe 'human_readable_visibility_ssi' do
    {
      'open' => 'Public',
      'low_res' => 'Public Low View',
      'emory_low' => 'Emory Low Download',
      'authenticated' => 'Emory High Download',
      'rose_high' => 'Rose High View',
      'restricted' => 'Private'
    }.each do |visibility, label|
      context "when visibility is #{visibility}" do
        let(:attributes) { { title: ['Test'], visibility: } }

        it "returns #{label}" do
          expect(solr_document['human_readable_visibility_ssi']).to eq label
        end
      end
    end
  end

  describe 'source_collection_title' do
    context 'when source_collection_id is blank' do
      let(:attributes) { { title: ['Test'], visibility: 'open' } }

      it 'does not index source_collection_title' do
        expect(solr_document['source_collection_title_ssim']).to be_nil
      end
    end

    context 'when source_collection_id is present' do
      let(:collection_id) { 'abc-123' }
      let(:collection) { instance_double('CollectionResource', title: ['My Collection']) }
      let(:attributes) { { title: ['Test'], visibility: 'open', source_collection_id: collection_id } }

      before do
        allow(Hyrax.query_service).to receive(:find_by).with(id: collection_id).and_return(collection)
      end

      it 'indexes the collection title' do
        expect(solr_document['source_collection_title_ssim']).to eq ['My Collection']
      end
    end

    context 'when the collection is not found' do
      let(:attributes) { { title: ['Test'], visibility: 'open', source_collection_id: 'missing-id' } }

      before do
        allow(Hyrax.query_service).to receive(:find_by)
          .with(id: 'missing-id')
          .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it 'returns nil' do
        expect(solr_document['source_collection_title_ssim']).to be_nil
      end
    end
  end

  describe 'manifest_cache_key' do
    let(:attributes) do
      {
        title:              ['Test title'],
        holding_repository: 'Library',
        rights_statement:   ['http://rightsstatements.org/vocab/InC/1.0/'],
        visibility:         'open'
      }
    end

    it 'indexes a manifest_cache_key' do
      expected_input = "Test title0Libraryhttp://rightsstatements.org/vocab/InC/1.0/open[]"
      expect(solr_document['manifest_cache_key_tesim']).to eq Digest::MD5.hexdigest(expected_input)
    end
  end

  describe 'representative_file_type' do
    context 'when representative_id is blank' do
      let(:attributes) { { title: ['Test'], visibility: 'open' } }

      it 'returns nil' do
        expect(solr_document['representative_file_type_ssi']).to be_nil
      end
    end

    context 'when representative is a PDF' do
      let(:attributes) { { title: ['Test'], visibility: 'open', representative_id: 'rep-456' } }
      let(:rep_doc) { instance_double(SolrDocument, pdf?: true) }

      before do
        allow(SolrDocument).to receive(:find).with('rep-456').and_return(rep_doc)
      end

      it 'indexes pdf' do
        expect(solr_document['representative_file_type_ssi']).to eq 'pdf'
      end
    end

    context 'when representative is not a PDF' do
      let(:attributes) { { title: ['Test'], visibility: 'open', representative_id: 'rep-456' } }
      let(:rep_doc) { instance_double(SolrDocument, pdf?: false) }

      before do
        allow(SolrDocument).to receive(:find).with('rep-456').and_return(rep_doc)
      end

      it 'returns nil' do
        expect(solr_document['representative_file_type_ssi']).to be_nil
      end
    end

    context 'when representative is not found in Solr' do
      let(:attributes) { { title: ['Test'], visibility: 'open', representative_id: 'missing-rep' } }

      before do
        allow(SolrDocument).to receive(:find)
          .with('missing-rep')
          .and_raise(Blacklight::Exceptions::RecordNotFound)
      end

      it 'returns nil' do
        expect(solr_document['representative_file_type_ssi']).to be_nil
      end
    end
  end

  describe 'human-readable fields' do
    let(:attributes) do
      {
        title:                 ['Test'],
        visibility:            'open',
        content_type:          'http://id.loc.gov/vocabulary/resourceTypes/aud',
        rights_statement:      ['http://rightsstatements.org/vocab/InC/1.0/'],
        re_use_license:        'https://creativecommons.org/licenses/by/4.0/',
        date_created:          '1940-10-15',
        date_issued:           '1941-01-15',
        data_collection_dates: ['2020-01-01'],
        conference_dates:      '1995-06-15',
        copyright_date:        '1922'
      }
    end

    before do
      allow(FormatLabelService.instance).to receive(:label).and_return('Audio')
      allow(RightsStatementLabelService.instance).to receive(:label).and_return('In Copyright')
      allow(LicensesLabelService.instance).to receive(:label).and_return('CC BY 4.0')
      allow(DateService.instance).to receive(:human_readable_date).and_return('Human Date')
    end

    it 'indexes human_readable_content_type' do
      expect(solr_document['human_readable_content_type_ssim']).to eq ['Audio']
    end

    it 'indexes human_readable_rights_statement' do
      expect(solr_document['human_readable_rights_statement_ssim']).to eq ['In Copyright']
    end

    it 'indexes human_readable_re_use_license' do
      expect(solr_document['human_readable_re_use_license_ssim']).to eq ['CC BY 4.0']
    end

    it 'indexes human_readable_date_created' do
      expect(solr_document['human_readable_date_created_tesim']).to eq ['Human Date']
    end

    it 'indexes human_readable_date_issued' do
      expect(solr_document['human_readable_date_issued_tesim']).to eq ['Human Date']
    end

    it 'indexes human_readable_data_collection_dates' do
      expect(solr_document['human_readable_data_collection_dates_tesim']).to eq ['Human Date']
    end

    it 'indexes human_readable_conference_dates' do
      expect(solr_document['human_readable_conference_dates_tesim']).to eq ['Human Date']
    end

    it 'indexes human_readable_copyright_date' do
      expect(solr_document['human_readable_copyright_date_tesim']).to eq ['Human Date']
    end
  end

  describe 'child_works_for_lux' do
    context 'when there are no members' do
      let(:attributes) { { title: ['Test'], visibility: 'open' } }

      it 'returns nil' do
        expect(solr_document['child_works_for_lux_tesim']).to be_nil
      end
    end

    context 'when there are child works' do
      let(:child_id) { Valkyrie::ID.new('child-1') }
      let(:child_work) do
        CurateGenericWorkResource.new(id: child_id, title: ['Child Work'])
      end
      let(:attributes) { { title: ['Parent'], visibility: 'open', member_ids: [child_id] } }

      before do
        allow(Hyrax.query_service).to receive(:find_by).with(id: child_id).and_return(child_work)
        allow(Hyrax::SolrService).to receive(:query)
          .with("id:#{child_id}", rows: 1)
          .and_return([{ 'thumbnail_path_ss' => '/thumb.jpg' }])
        allow(Hyrax::SolrService).to receive(:query)
          .with(start_with("label_tesim:"), any_args)
          .and_return([])
      end

      it 'indexes formatted child work entries' do
        expect(solr_document['child_works_for_lux_tesim']).to eq ["#{child_id}, /thumb.jpg, Child Work"]
      end
    end
  end

  describe 'parent_work_for_lux' do
    context 'when there are no parents' do
      let(:attributes) { { title: ['Test'], visibility: 'open' } }

      it 'returns nil' do
        expect(solr_document['parent_work_for_lux_tesim']).to be_nil
      end
    end

    context 'when there is a parent work' do
      let(:parent_id) { Valkyrie::ID.new('parent-1') }
      let(:parent_work) do
        CurateGenericWorkResource.new(id: parent_id, title: ['Parent Work'])
      end
      let(:attributes) { { title: ['Child'], visibility: 'open' } }

      before do
        allow(Hyrax.custom_queries).to receive(:find_parent_works).and_return([parent_work])
      end

      it 'indexes formatted parent work entry' do
        expect(solr_document['parent_work_for_lux_tesim']).to eq ["#{parent_id}, Parent Work"]
      end
    end
  end

  describe 'full text data' do
    context 'when no full text file set exists' do
      let(:attributes) { { title: ['Test'], visibility: 'open' } }

      before do
        allow(Hyrax::SolrService).to receive(:query).and_return([])
      end

      it 'does not index full text' do
        expect(solr_document['all_text_timv']).to be_nil
        expect(solr_document['all_text_tsimv']).to be_nil
      end
    end

    context 'when full text file set exists' do
      let(:resource_id) { Valkyrie::ID.new('work-id') }
      let(:attributes) { { id: resource_id, title: ['Test'], visibility: 'open' } }
      let(:file_set) { instance_double('FileSetResource') }
      let(:primary_file) { instance_double('Hyrax::FileMetadata', content: 'Full text content here') }
      let(:file_service) { instance_double('FileSetFileService', primary_file:) }

      before do
        allow(Hyrax::SolrService).to receive(:query)
          .with("label_tesim:\"Full Text Data - #{resource_id}\"", fl: "id", sort: "date_uploaded_dtsi desc", rows: 1)
          .and_return([{ "id" => "fs-1" }])
        allow(Hyrax.query_service).to receive(:find_by).with(id: "fs-1").and_return(file_set)
        allow(Hyrax.config.file_set_file_service).to receive(:new).with(file_set:).and_return(file_service)
      end

      it 'indexes full text data' do
        expect(solr_document['all_text_timv']).to eq 'Full text content here'
        expect(solr_document['all_text_tsimv']).to eq 'Full text content here'
      end
    end
  end
end
