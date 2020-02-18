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
  end
end
