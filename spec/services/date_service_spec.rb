# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DateService do
  let(:service) { described_class.instance }

  describe 'getting the human-readable version' do
    it 'provides a string for unknown dates' do
      expect(service.human_readable_date('XXXX')).to eq('unknown')
    end

    it 'provides a string for known month with unknown year' do
      expect(service.human_readable_date('XXXX-10')).to eq('October (year unknown)')
    end

    it 'provides a string for single years' do
      expect(service.human_readable_date('1934')).to eq('1934')
    end

    it 'provides a string for years with a final unspecified digit' do
      expect(service.human_readable_date('193X')).to eq('1930s')
    end

    it 'provides a string for years with two final unspecified digits' do
      expect(service.human_readable_date('20XX')).to eq('2000s')
      expect(service.human_readable_date('19XX')).to eq('1900s')
    end

    it 'provides a string for uncertain years' do
      expect(service.human_readable_date('1934?')).to eq('1934 approx.')
    end

    it 'provides a string for known year ranges' do
      expect(service.human_readable_date('1981/1985')).to eq('1981 to 1985')
    end

    it 'provides a string for year ranges with unspecified digits' do
      expect(service.human_readable_date('194X/195X')).to eq('1940s to 1950s')
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

    it 'provides a string for dates with known month and year but unknown day' do
      expect(service.human_readable_date('1962-02')).to eq('February 1962')
    end

    it 'provides a string for dates uncertain month and year but unknown day' do
      expect(service.human_readable_date('1940-02~')).to eq('February 1940 approx.')
    end

    it 'provides a string for dates with uncertain year but unknown month and day' do
      expect(service.human_readable_date('1976~')).to eq('1976 approx.')
    end

    it 'leaves dates with unexpected formatting unaltered' do
      expect(service.human_readable_date('2019-XX-07')).to eq('2019-XX-07')
    end
  end
end
