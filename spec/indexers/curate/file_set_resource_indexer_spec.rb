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
end
