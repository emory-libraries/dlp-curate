# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IiifUrlBuilderService, :clean do
  let(:iiif_builder_service) { described_class.new(file_set_id: file_set.id, size: '260,') }
  let(:iiif_builder_service_with_alternate_id) { described_class.new(file_set_id:, size: '260,') }
  let(:user) { FactoryBot.create(:admin) }
  let(:file_set_id) { '7956djh9wp-cor/files/efce22de-c771-469e-b0df-41094b21684c' }
  let(:file_set_id_base) { '7956djh9wp-cor' }
  let(:file_set) do
    FactoryBot.create(:file_set, user:, title: ['Some title'])
  end
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  before do
    Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
  end

  around do |example|
    ENV['IIIF_SERVER_URL'] = 'http://localhost:3000/cantaloupe/iiif/2/'
    example.run
    ENV['IIIF_SERVER_URL'] = nil
  end

  context 'when using the s3 Fedora adapter' do
    let(:checksum_value) { file_set.preservation_master_file.checksum.value }
    let(:sha1_url) { "http://localhost:3000/cantaloupe/iiif/2/#{checksum_value}/full/260,/0/default.jpg" }
    let(:sha1_info_url) { "http://localhost:3000/cantaloupe/iiif/2/#{checksum_value}" }

    context 'when given a fileset id' do
      it 'returns a sha1' do
        expect(iiif_builder_service.sha1).to eq(checksum_value.gsub('urn:sha1:', ''))
      end
      it 'returns a full url with the sha1' do
        expect(iiif_builder_service.sha1_url).to eq(sha1_url)
      end

      it 'returns a full info url with the sha1' do
        expect(iiif_builder_service.sha1_info_url).to eq(sha1_info_url)
      end
    end

    context 'when given a fileset without the proper checksums' do
      it 'returns unknown' do
        file_set.preservation_master_file = nil
        expect(iiif_builder_service.sha1).to eq('unknown')
      end
    end

    # ManifestBuilderService passes the preferred file's FileMetadata id for
    # Valkyrie works, so the lookup returns a Hyrax::FileMetadata.
    context 'when given a Valkyrie FileMetadata id' do
      let(:valkyrie_service) { described_class.new(file_set_id: 'fm-123', size: '260,') }
      let(:checksums) { ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7', 'urn:sha1:7b16f8f03531aea38080f6c9b69792f3dae65e64'] }
      let(:file_metadata) do
        Hyrax::FileMetadata.new(id: Valkyrie::ID.new('fm-123'), file_set_id: Valkyrie::ID.new('fs-123'),
                                original_checksum: checksums)
      end

      before do
        allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
        allow(Hyrax.query_service).to receive(:find_by).with(id: 'fm-123').and_return(file_metadata)
      end

      it 'builds the urls from the FileMetadata sha1' do
        expect(valkyrie_service.sha1).to eq('7b16f8f03531aea38080f6c9b69792f3dae65e64')
        expect(valkyrie_service.sha1_url)
          .to eq('http://localhost:3000/cantaloupe/iiif/2/7b16f8f03531aea38080f6c9b69792f3dae65e64/full/260,/0/default.jpg')
        expect(valkyrie_service.sha1_info_url)
          .to eq('http://localhost:3000/cantaloupe/iiif/2/7b16f8f03531aea38080f6c9b69792f3dae65e64')
      end

      context 'without a sha1 checksum' do
        let(:checksums) { ['urn:md5:5b8fdd56bd296b2758c9e993175a7db7'] }

        it 'returns unknown' do
          expect(valkyrie_service.sha1).to eq('unknown')
        end
      end
    end
  end

  context 'when not using the Fedora s3 adapter' do
    let(:file_set_id_url) { "http://localhost:3000/cantaloupe/iiif/2/#{file_set.id}/full/260,/0/default.jpg" }
    let(:file_id_info_url) { "http://localhost:3000/cantaloupe/iiif/2/#{file_set.id}" }
    it 'returns a full url with the file_set id' do
      expect(iiif_builder_service.file_set_id_url).to eq(file_set_id_url)
    end

    it 'returns a full info url with the file_set id' do
      expect(iiif_builder_service.file_id_info_url).to eq(file_id_info_url)
    end
  end

  context 'when given the file_set_id in hyrax.rb' do
    let(:file_set) do
      FactoryBot.create(:file_set, user:, id: file_set_id_base, title: ['Some title'])
    end

    it 'returns only the base id' do
      expect(iiif_builder_service_with_alternate_id.file_set_id_base).to eq(file_set_id_base)
    end
  end
end
