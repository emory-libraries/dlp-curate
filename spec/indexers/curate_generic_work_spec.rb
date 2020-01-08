# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CurateGenericWorkIndexer do
  let(:solr_document) { indexer.generate_solr_document }
  let(:work) { CurateGenericWork.new(attributes) }
  let(:indexer) { described_class.new(work) }

  describe 'integer years created for date slider facet' do
    context 'with a date_created' do
      let(:attributes) do
        {
          id:           '123',
          date_created: '1940-10-15'
        }
      end

      it 'indexes the year created' do
        expect(solr_document['year_created_isim']).to eq [1940]
      end

      it 'indexes year for lux' do
        expect(solr_document['year_for_lux_isim']).to eq [1940]
      end
    end

    context 'when date_created field is blank' do
      let(:attributes) do
        {
          id: '123'
        }
      end

      it 'doesn\'t index the year created' do
        expect(solr_document['year_created_isim']).to eq nil
      end

      it 'doesn\'t index year for lux' do
        expect(solr_document['year_for_lux_isim']).to eq nil
      end
    end
  end

  describe 'integer years issued for date slider facet' do
    context 'with a date_issued' do
      let(:attributes) do
        {
          id:          '123',
          date_issued: '1940-10-15'
        }
      end

      it 'indexes the year issued' do
        expect(solr_document['year_issued_isim']).to eq [1940]
      end

      it 'indexes year for lux' do
        expect(solr_document['year_for_lux_isim']).to eq [1940]
      end
    end

    context 'when date_issued field is blank' do
      let(:attributes) do
        {
          id: '123'
        }
      end

      it 'doesn\'t index the year issued' do
        expect(solr_document['year_issued_isim']).to eq nil
      end

      it 'doesn\'t index year for lux' do
        expect(solr_document['year_for_lux_isim']).to eq nil
      end
    end
  end

  describe 'year for lux' do
    context 'when date_created and date_issued fields have the same year' do
      let(:attributes) do
        {
          id:           '123',
          date_created: '1940-10-15',
          date_issued:  '1940-11-15'
        }
      end

      it 'deduplicates the year fields' do
        expect(solr_document['year_for_lux_isim']).to eq [1940]
      end
    end

    context 'when date_created and date_issued fields have different years' do
      let(:attributes) do
        {
          id:           '123',
          date_created: '1940-10-15',
          date_issued:  '1941-01-15'
        }
      end

      it 'saves both years and saves them in order' do
        expect(solr_document['year_for_lux_isim']).to eq [1940, 1941]
      end
    end
  end
end
