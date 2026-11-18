# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Curate::FileSetResourceIndexer do
  subject(:solr_document) { described_class.new(resource: file_set).to_solr }

  let(:file_set) { FileSetResource.new(id: Valkyrie::ID.new('fs-123'), title: ['0008.tif']) }
  let(:file_metadata) do
    Hyrax::FileMetadata.new(
      id: Valkyrie::ID.new('fm-123'), file_set_id: file_set.id, original_filename: '0008.tif',
      mime_type: 'image/tiff', recorded_size: [5802], date_created: ['2026:10:01 15:14:00'],
      file_path: ['/tmp/0008.tif'], creating_os: ['Mac OS'], alpha_channels:,
      original_checksum: ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7']
    )
  end
  let(:alpha_channels) { ['gray'] }
  let(:channels) { [] }

  before { file_metadata.channels = channels }

  before do
    allow(Hyrax.config.file_set_file_service).to receive(:new)
      .and_return(instance_double(Hyrax.config.file_set_file_service, primary_file: file_metadata))
  end

  it 'indexes the Curate characterization fields from the primary FileMetadata' do
    expect(solr_document).to include(
      'file_name_ssim' => '0008.tif', 'date_created_ssim' => ['2026:10:01 15:14:00'],
      'file_path_ssim' => ['/tmp/0008.tif'], 'creating_os_ssim' => ['Mac OS'], 'alpha_channels_ssi' => 'gray',
      'original_checksum_ssim' => ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7']
    )
  end

  # SolrDocument#file_size falls back to Hyrax's integer field; a file_size_ssim
  # array would break Hyrax's analytics, which sums SolrDocument#file_size.
  it 'leaves the file size in the Hyrax file_size_lts field' do
    expect(solr_document).to include('file_size_lts' => 5802)
    expect(solr_document).not_to have_key('file_size_ssim')
  end

  context 'when FITS reports audio channels' do
    let(:channels) { ['2'] }

    it 'indexes the detected alpha channels rather than the audio channel count' do
      expect(solr_document['alpha_channels_ssi']).to eq 'gray'
    end

    context 'without detected alpha channels' do
      let(:alpha_channels) { [] }

      it 'does not index alpha_channels_ssi' do
        expect(solr_document).not_to have_key('alpha_channels_ssi')
      end
    end
  end

  describe 'full text fields' do
    let(:fixtures) { Rails.root.join('spec', 'fixtures', 'book_page') }
    let(:transcript) { text_file('0003_transcript.txt', Hyrax::FileMetadata::Use::TRANSCRIPT) }
    let(:alto) { text_file('0003_alto.xml', Hyrax::FileMetadata::Use::EXTRACTED_TEXT) }
    let(:parent) { CurateGenericWorkResource.new(id: Valkyrie::ID.new('work-1')) }

    def text_file(name, use)
      Hyrax::FileMetadata.new(id: Valkyrie::ID.new("fm-#{name}"), file_set_id: file_set.id, original_filename: name, pcdm_use: [use])
                         .tap { |fm| allow(fm).to receive(:content).and_return(File.read(fixtures.join(name))) }
    end

    # The Curate file queries are only registered during the Valkyrie transition, not in the test env,
    # so they are added onto the real query container.
    let(:custom_queries) do
      SimpleDelegator.new(Hyrax.custom_queries).tap do |queries|
        queries.define_singleton_method(:find_transcript_file) { |**| nil }
        queries.define_singleton_method(:find_extracted_text) { |**| nil }
        queries.define_singleton_method(:find_parent_work) { |**| nil }
      end
    end

    before do
      file_metadata.width = ['1200']
      file_metadata.height = ['1800']
      allow(custom_queries).to receive(:find_transcript_file).with(file_set:).and_return(transcript)
      allow(custom_queries).to receive(:find_extracted_text).with(file_set:).and_return(alto)
      allow(custom_queries).to receive(:find_parent_work).with(resource: file_set).and_return(parent)
      allow(Hyrax).to receive(:custom_queries).and_return(custom_queries)
    end

    it 'indexes the transcript, ALTO coordinates and parent work used by IIIF search' do
      expect(solr_document['transcript_text_tesi']).to eq File.read(fixtures.join('0003_transcript.txt'))
      expect(solr_document['alto_xml_tesi'])
        .to eq Curate::TextExtraction::AltoReader.new(File.read(fixtures.join('0003_alto.xml')), '1200', '1800').json
      expect(solr_document['is_page_of_ssi']).to eq 'work-1'
    end

    context 'without transcript or ALTO files' do
      before do
        allow(custom_queries).to receive(:find_transcript_file).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        allow(custom_queries).to receive(:find_extracted_text).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it 'still indexes the parent work' do
        expect(solr_document.keys).not_to include('transcript_text_tesi', 'alto_xml_tesi')
        expect(solr_document['is_page_of_ssi']).to eq 'work-1'
      end
    end

    context 'when the extracted text is not ALTO XML' do
      let(:alto) { text_file('0003_transcript.txt', Hyrax::FileMetadata::Use::EXTRACTED_TEXT) }

      it 'does not index it as ALTO' do
        expect(solr_document).not_to have_key('alto_xml_tesi')
      end
    end
  end

  describe 'label' do
    let(:file_set) { FileSetResource.new(id: Valkyrie::ID.new('fs-123'), title: ['PDF for volume'], label: 'PDF for volume') }

    it 'indexes the label as the AF indexer does' do
      expect(solr_document).to include('label_tesim' => 'PDF for volume', 'label_ssi' => 'PDF for volume')
    end

    it 'names the file in its manifest download entry' do
      # Solr returns the multivalued label_tesim field as an array.
      allow(SolrDocument).to receive(:find).with('fs-123')
                                           .and_return(SolrDocument.new(solr_document.merge('label_tesim' => [solr_document['label_tesim']])))

      expect(Hyrax::ManifestHelper.new('http://localhost:3000').build_rendering('fs-123')['label'])
        .to eq 'Download whole resource: PDF for volume'
    end

    context 'without a label' do
      let(:file_set) { FileSetResource.new(id: Valkyrie::ID.new('fs-123'), title: ['0008.tif']) }

      it 'does not index one' do
        expect(solr_document.keys).not_to include('label_tesim', 'label_ssi')
      end
    end
  end
end
