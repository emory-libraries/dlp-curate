# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IiifUrlBuilderService, :clean do
  let(:iiif_builder_service) { described_class.new(file_set_id: file_set.id, size: '260,') }
  let(:user) { FactoryBot.create(:admin) }
  let(:file_set) { FactoryBot.create(:file_set, user:, title: ['Some title']) }
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:valkyrie_fs_id) { Valkyrie::ID.new("f2760d05-bb8f-4da9-bdb9-8a749500de79") }
  let(:valkyrie_file_set) { FileSetResource.new(id: valkyrie_fs_id) }
  before { Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file) }

  around do |example|
    ENV['IIIF_SERVER_URL'] = 'http://localhost:3000/cantaloupe/iiif/2/'
    example.run
    ENV['IIIF_SERVER_URL'] = nil
  end

  context 'when given an ActiveFedora FileSet id' do
    let(:checksum_value) { file_set.preservation_master_file.checksum.value }
    let(:sha1_url) { "http://localhost:3000/cantaloupe/iiif/2/#{checksum_value}/full/260,/0/default.jpg" }
    let(:sha1_info_url) { "http://localhost:3000/cantaloupe/iiif/2/#{checksum_value}" }

    context 'when given a fileset id' do
      it('returns a sha1') { expect(iiif_builder_service.sha1).to eq(checksum_value.gsub('urn:sha1:', '')) }
      it('returns a full url with the sha1') { expect(iiif_builder_service.iiif_url).to eq(sha1_url) }
      it('returns a full info url with the sha1') { expect(iiif_builder_service.info_url).to eq(sha1_info_url) }
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
      let(:valkyrie_fm_id) { "f1bc9f08-e398-4982-98c8-3963cfc815d5" }
      let(:valkyrie_service) { described_class.new(file_set_id: valkyrie_fm_id, size: '260,') }
      let(:file_metadata) { Hyrax::FileMetadata.new(id: Valkyrie::ID.new(valkyrie_fm_id), file_set_id: valkyrie_fs_id) }
      before do
        allow(Hyrax.query_service).to receive(:find_by).with(id: valkyrie_fm_id).and_return(file_metadata)
        allow(Hyrax.query_service).to receive(:find_by).with(id: valkyrie_fs_id).and_return(valkyrie_file_set)
        allow(valkyrie_file_set).to receive(:preferred_file).and_return(:preservation_master_file)
      end

      it 'pulls the file_set id and uses it in url' do
        expect(valkyrie_service.iiif_url)
          .to eq('http://localhost:3000/cantaloupe/iiif/2/fedora7--original--f2760d05-bb8f-4da9-bdb9-8a749500de79/full/260,/0/default.jpg')
        expect(valkyrie_service.info_url)
          .to eq('http://localhost:3000/cantaloupe/iiif/2/f2760d05-bb8f-4da9-bdb9-8a749500de79')
      end
    end

    context 'when given a Valkyrie FileSetResource id' do
      let(:valkyrie_service) { described_class.new(file_set_id: valkyrie_fs_id, size: '260,') }
      before do
        allow(Hyrax.query_service).to receive(:find_by).with(id: valkyrie_fs_id).and_return(valkyrie_file_set)
        allow(valkyrie_file_set).to receive(:preferred_file).and_return(:intermediate_file)
      end

      it 'pulls the file_set id and uses it in url' do
        expect(valkyrie_service.iiif_url)
          .to eq('http://localhost:3000/cantaloupe/iiif/2/fedora7--intermediate--f2760d05-bb8f-4da9-bdb9-8a749500de79/full/260,/0/default.jpg')
        expect(valkyrie_service.info_url)
          .to eq('http://localhost:3000/cantaloupe/iiif/2/f2760d05-bb8f-4da9-bdb9-8a749500de79')
      end
    end
  end

  context 'when given the file_set_id in hyrax.rb' do
    let(:iiif_builder_service_with_alternate_id) { described_class.new(file_set_id:, size: '260,') }
    let(:file_set) { FactoryBot.create(:file_set, user:, id: file_set_id_base, title: ['Some title']) }
    let(:file_set_id) { '7956djh9wp-cor/files/efce22de-c771-469e-b0df-41094b21684c' }
    let(:file_set_id_base) { '7956djh9wp-cor' }

    it 'returns only the base id' do
      expect(iiif_builder_service_with_alternate_id.file_set_id_base).to eq(file_set_id_base)
    end
  end
end
