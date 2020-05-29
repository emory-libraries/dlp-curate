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

  describe 'sort fields' do
    let(:attributes) do
      {
        id:           '123',
        title:        ['Some title'],
        creator:      ['Some creator'],
        date_created: '1940-10-15',
        date_issued:  '1941-01-15'
      }
    end

    it 'indexes sort fields for title and creator' do
      expect(solr_document['title_ssort']).to eq 'Some title'
      expect(solr_document['creator_ssort']).to eq 'Some creator'
    end

    it 'indexes sort field for date containing earliest year' do
      expect(solr_document['year_for_lux_ssi']).to eq 1940
    end

    context 'when year for lux is not indexed' do
      let(:attributes) do
        {
          id:    '123',
          title: ['Some title']
        }
      end

      it 'doesn\'t index a sort field for date' do
        expect(solr_document['year_for_lux_ssi']).to eq nil
      end
    end

    context 'when year for lux is unknown' do
      let(:attributes) do
        {
          id:           '123',
          title:        ['Some title'],
          date_created: 'XXXX',
          date_issued:  'XXXX'
        }
      end

      it 'doesn\'t index a sort field for date' do
        expect(solr_document['year_for_lux_ssi']).to eq nil
      end
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

  describe 'failed_preservation_events' do
    context 'when preservation_event is empty' do
      let(:attributes) do
        {
          id:    '123',
          title: ['A title']
        }
      end

      it 'returns empty array' do
        expect(solr_document['failed_preservation_events_ssim']).to be_nil
      end
    end

    context 'when preservation_event has failures' do
      let(:attributes) do
        {
          id:    '123',
          title: ['A title'],
          preservation_event_attributes: [{'event_type' => 'Yackety', 'event_start' => DateTime.current, 'outcome' => 'Failure',
              'event_details' => "Smackety", 'software_version' => 'FITS v1.5.0', 'initiating_user' => "10"}]
        }
      end

      it 'returns an array of hashes' do
        event_start = solr_document['failed_preservation_events_ssim'].first[:event_start]
        expect(solr_document['failed_preservation_events_ssim']).to eq([{event_details: ["Smackety"], event_start: event_start}])
      end
    end
  end
end
