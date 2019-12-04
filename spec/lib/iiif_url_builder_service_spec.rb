# frozen_string_literal: true
# rubocop:disable RSpec/AnyInstance

require 'rails_helper'

RSpec.describe IiifUrlBuilderService, :clean do
  let(:iiif_builder_service) { described_class.new(file_set_id: file_set.id, size: '260,') }
  let(:iiif_builder_service_with_alternate_id) { described_class.new(file_set_id: file_set_id, size: '260,') }
  let(:user) { FactoryBot.create(:admin) }
  let(:file_set_id) { '7956djh9wp-cor/files/efce22de-c771-469e-b0df-41094b21684c' }
  let(:file_set_id_base) { '7956djh9wp-cor' }
  let(:file_set) do
    FactoryBot.create(:file_set, user: user, title: ['Some title'])
  end

  before do
    ENV['IIIF_SERVER_URL'] = 'http://localhost:3000/cantaloupe/iiif/2/'
  end

  let(:original_checksum) do
    ['urn:md5:da674abf5cc0750158ebe9f8fdb83faf',
     'urn:sha1:fba6a26214287bb0c50ecb2e4922041dcb84b256',
     'urn:sha256:7399acb3f34ec4cb06a55b0ca79e637fee3552cc599d7cd2eb6b17e3a2db94e7']
  end
  context 'when using the s3 Fedora adapter' do
    let(:sha1_url) { 'http://localhost:3000/cantaloupe/iiif/2/fba6a26214287bb0c50ecb2e4922041dcb84b256/full/260,/0/default.jpg' }
    let(:sha1_info_url) { "http://localhost:3000/cantaloupe/iiif/2/fba6a26214287bb0c50ecb2e4922041dcb84b256" }

    context 'when given a fileset id' do
      it 'returns a sha1' do
        allow_any_instance_of(FileSet).to receive(:original_checksum).and_return(original_checksum)
        expect(iiif_builder_service.sha1).to eq('fba6a26214287bb0c50ecb2e4922041dcb84b256')
      end
      it 'returns a full url with the sha1' do
        allow_any_instance_of(FileSet).to receive(:original_checksum).and_return(original_checksum)
        expect(iiif_builder_service.sha1_url).to eq(sha1_url)
      end

      it 'returns a full info url with the sha1' do
        allow_any_instance_of(FileSet).to receive(:original_checksum).and_return(original_checksum)
        expect(iiif_builder_service.sha1_info_url).to eq(sha1_info_url)
      end
    end

    context 'when given a fileset without the proper checksums' do
      it 'returns unknown' do
        allow(file_set).to receive(:original_checksum).and_return([])
        expect(iiif_builder_service.sha1).to eq('unknown')
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
    it 'returns only the base id' do
      expect(iiif_builder_service_with_alternate_id.file_set_id_base).to eq(file_set_id_base)
    end
  end
end
