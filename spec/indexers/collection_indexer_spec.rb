# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CurateCollectionIndexer do
  let(:solr_document) { indexer.generate_solr_document }
  let(:collection) { Collection.new(attributes) }
  let(:indexer) { described_class.new(collection) }

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

      it 'indexes the banner path for each collection' do
        banner_info = CollectionBrandingInfo.new(
          collection_id: collection.id, filename: filename,
          role: "banner", target_url: ""
        )
        banner_info.save file.local_path

        expect(solr_document['banner_path_ss']).to eq(
          '/branding/' +
          collection.id.to_s +
          '/banner' +
          filename
        )
      end
    end
  end
end
