# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Curate::FileSetPresenter do
  subject(:presenter) { described_class.new(solr_document, ability) }
  let(:ability) { instance_double(Ability) }
  let(:solr_document) { SolrDocument.new(attributes) }

  describe '#characterization_metadata' do
    # Fields as written for a Valkyrie FileSet by Curate::FileSetResourceIndexer.
    let(:attributes) do
      { 'id' => '53f477fd-1a9c-4a8f-8ca9-d91458b78c24', 'has_model_ssim' => ['FileSet'],
        'file_name_ssim' => ['0008.tif'], 'file_path_ssim' => ['/tmp/0008.tif20261001-3280353-arr2iz.tif'],
        'file_size_lts' => 5802, 'mime_type_ssi' => 'image/tiff', 'format_label_tesim' => ['TIFF EXIF'],
        'height_is' => 2249, 'width_is' => 1500, 'compression_tesim' => ['T6/Group 4 Fax'],
        'color_space_tesim' => ['WhiteIsZero'], 'orientation_tesim' => ['normal*'], 'alpha_channels_ssi' => 'gray',
        'date_created_ssim' => ['2026:10:01 15:14:00'], 'creating_os_ssim' => ['Mac OS'],
        'original_checksum_ssim' => ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7'] }
    end

    it 'includes the characterization indexed for a Valkyrie FileSet' do
      expect(presenter.characterization_metadata).to include(
        file_name: ['0008.tif'], file_size: 5802, compression: ['T6/Group 4 Fax'],
        color_space: ['WhiteIsZero'], alpha_channels: 'gray', created: ['2026:10:01 15:14:00'],
        creating_os: ['Mac OS'], original_checksum: ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7']
      )
    end
  end

  describe '#label_for_term' do
    let(:attributes) { { 'id' => 'file-set' } }

    it 'uses the configured label for creating_os' do
      expect(presenter.label_for_term(:creating_os)).to eq 'Creating OS'
    end

    it 'titleizes other terms' do
      expect(presenter.label_for_term(:file_size)).to eq 'File Size'
    end
  end
end
