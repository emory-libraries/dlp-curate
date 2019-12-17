# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DateService do
  let(:service) { described_class.instance }

  describe 'getting the human-readable version' do
    it 'provides a string for unknown dates' do
      expect(service.human_readable_date('XXXX')).to eq('unknown')
    end

    it 'provides a string for single years' do
      expect(service.human_readable_date('1934')).to eq('1934')
    end

    it 'provides a string for years with an unspecified digit' do
      expect(service.human_readable_date('193X')).to eq('1930s')
    end

    it 'provides a string for uncertain years' do
      expect(service.human_readable_date('1934?')).to eq('1934 approx.')
    end

    it 'provides a string for year ranges with unspecified digits' do
      expect(service.human_readable_date('194X/195X')).to eq('within the 1940s or 1950s')
    end

    it 'provides a string for uncertain year ranges' do
      expect(service.human_readable_date('1942?/1944?')).to eq('between 1942 and 1944')
    end

    it 'provides a string for exact dates in YYYY-MM-DD format' do
      expect(service.human_readable_date('1934-09-07')).to eq('September 7, 1934')
    end

    it 'provides a string for dates with known day and month but unknown year' do
      expect(service.human_readable_date('XXXX-09-07')).to eq('September 7, year unknown')
    end
  end
end
