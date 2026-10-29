# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SolrDocument do
  subject(:document) { described_class.new(attributes) }

  describe 'characterization readers' do
    context 'with a FileSet indexed by the AF Curate::FileSetIndexer' do
      let(:attributes) do
        { 'id' => 'af-file-set', 'file_size_ssim' => ['5802'], 'date_created_ssim' => ['2020:01:01 10:00:00'],
          'valid_ssim' => ['true'], 'well_formed_ssim' => ['true'], 'character_set_ssim' => ['UTF-8'],
          'byte_order_ssim' => ['little endian'], 'color_space_ssim' => ['WhiteIsZero'],
          'compression_ssim' => ['T6/Group 4 Fax'], 'profile_name_ssim' => ['sRGB'], 'profile_version_ssim' => ['2.1.0'],
          'original_checksum_tesim' => ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7'] }
      end

      it 'reads the AF fields' do
        expect(document.file_size).to eq ['5802']
        expect(document.created).to eq ['2020:01:01 10:00:00']
        expect(document.valid).to eq ['true']
        expect(document.well_formed).to eq ['true']
        expect(document.character_set).to eq ['UTF-8']
        expect(document.byte_order).to eq ['little endian']
        expect(document.color_space).to eq ['WhiteIsZero']
        expect(document.compression).to eq ['T6/Group 4 Fax']
        expect(document.profile_name).to eq ['sRGB']
        expect(document.profile_version).to eq ['2.1.0']
        expect(document.original_checksum).to eq ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7']
      end
    end

    context 'with a FileSet indexed by the Valkyrie Curate::FileSetResourceIndexer' do
      let(:attributes) do
        { 'id' => 'valkyrie-file-set', 'file_size_lts' => 5802, 'valid_tesim' => ['true'],
          'well_formed_tesim' => ['true'], 'character_set_tesim' => ['UTF-8'], 'byte_order_tesim' => ['big endian'],
          'color_space_tesim' => ['WhiteIsZero'], 'compression_tesim' => ['T6/Group 4 Fax'],
          'profile_name_tesim' => ['sRGB'], 'profile_version_tesim' => ['2.1.0'], 'creating_os_ssim' => ['Mac OS'],
          'original_checksum_ssim' => ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7', 'urn:sha1:7b16f8f03531aea38080f6c9b69792f3dae65e64'] }
      end

      it 'falls back to the Hyrax Valkyrie fields' do
        expect(document.file_size).to eq 5802
        expect(document.valid).to eq ['true']
        expect(document.well_formed).to eq ['true']
        expect(document.character_set).to eq ['UTF-8']
        expect(document.byte_order).to eq ['big endian']
        expect(document.color_space).to eq ['WhiteIsZero']
        expect(document.compression).to eq ['T6/Group 4 Fax']
        expect(document.profile_name).to eq ['sRGB']
        expect(document.profile_version).to eq ['2.1.0']
        expect(document.creating_os).to eq ['Mac OS']
        expect(document.original_checksum)
          .to eq ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7', 'urn:sha1:7b16f8f03531aea38080f6c9b69792f3dae65e64']
      end
    end

    context 'without characterization fields' do
      let(:attributes) { { 'id' => 'empty-file-set' } }

      it 'returns nil' do
        expect(document.file_size).to be_nil
        expect(document.compression).to be_nil
        expect(document.original_checksum).to be_nil
      end
    end
  end
end
