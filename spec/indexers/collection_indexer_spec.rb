# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CurateCollectionIndexer do
  let(:solr_document) { indexer.generate_solr_document }
  let(:collection) { Collection.new(attributes) }
  let(:indexer) { described_class.new(collection) }

  describe 'save source_collection on collection' do
    context 'when source_collection_id is empty' do
      let(:attributes) do
        {
          id:    '123',
          title: ['A title']
        }
      end

      it 'returns empty array' do
        expect(solr_document['source_collection_id_tesim']).to eq(nil)
      end
    end

    context 'when source_collection_id is present' do
      let(:collection_new) { FactoryBot.create(:collection_lw, id: 'abc123', title: ['Test title collection123']) }
      let(:attributes) do
        {
          id:                   '123',
          title:                ['A title'],
          source_collection_id: 'abc123'
        }
      end

      before do
        allow(Collection).to receive(:create).and_return(collection_new)
      end

      it 'returns correct source collection title' do
        expect(solr_document['source_collection_title_ssim']).to eq(['Test title collection123'])
      end
    end
  end

  describe 'save deposit_collection' do
    context 'when source_collection_id is empty' do
      let(:attributes) do
        {
          id:    '123',
          title: ['A title']
        }
      end

      it 'returns empty array' do
        expect(solr_document['deposit_collection_ids_tesim']).to be_nil
      end
    end

    context 'when deposit_collection_id is present' do
      let(:collection_new) { FactoryBot.create(:collection_lw, id: 'abc123', title: ['Test title collection123']) }
      let(:attributes) do
        {
          id:                    '123',
          title:                 ['A title'],
          deposit_collection_ids: ['abc123']
        }
      end

      before do
        allow(Collection).to receive(:create).and_return(collection_new)
      end

      it 'returns correct deposit collection title' do
        expect(solr_document['deposit_collection_titles_tesim']).to eq(['Test title collection123'])
      end
    end
  end

  describe 'sort fields' do
    let(:attributes) do
      {
        id:      '123',
        title:   ['Some title'],
        creator: ['Some creator']
      }
    end

    it 'indexes sort fields for title and creator' do
      expect(solr_document['title_ssort']).to eq 'Some title'
      expect(solr_document['creator_ssort']).to eq 'Some creator'
    end

    context 'when title has a leading article' do
      let(:attributes) do
        {
          id:    '123',
          title: ['A title']
        }
      end

      it 'indexes title sort field without leading articles' do
        expect(solr_document['title_ssort']).to eq 'title'
      end
    end

    it 'returns nil when collection has no banner attached' do
      expect(solr_document['banner_path_ss']).to be_falsey
    end

    context 'when collection has banner attached' do
      let(:filename) { '/world.png' }
      let(:file)     { fixture_file_upload(filename, 'image/png') }

      before do
        banner_info = CollectionBrandingInfo.new(
          collection_id: collection.id, filename: filename,
          role: "banner", target_url: ""
        )
        banner_info.save file.local_path
      end

      it 'indexes the banner path for each collection' do
        expect(solr_document['banner_path_ss']).to eq(
          '/branding/' +
          collection.id.to_s +
          '/banner' +
          filename
        )
      end

      context 'banner path imported from different environment' do
        it 'indexes the banner path correctly' do
          sanitized_path = indexer.path_sanitized('/mnt/prod_efs/uploads/dlp-curate/branding/914nk98sfv-cor/banner/40644j0ztx-cor.jpg')

          expect(sanitized_path).to eq('/branding/914nk98sfv-cor/banner/40644j0ztx-cor.jpg')
        end
      end
    end
  end
end
