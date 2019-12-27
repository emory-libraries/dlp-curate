# frozen_string_literal: true
require 'rails_helper'

RSpec.describe YearParser do
  describe '::integer_years' do
    subject { described_class.integer_years(dates) }

    context 'ISO 8601 date format' do
      let(:dates) { ['1941-10-01'] }
      it { is_expected.to eq [1941] }
    end

    context 'just the year' do
      let(:dates) { '1953' }
      it { is_expected.to eq [1953] }
    end

    context 'just year and month' do
      let(:dates) { '1953-10' }
      it { is_expected.to eq [1953] }
    end

    context 'multiple dates' do
      let(:unsorted_dates) { ['1941-10-01', '1935', '1945'] }
      let(:dates) { unsorted_dates }
      let(:sorted_dates) { subject }

      it 'returns the years in sorted order' do
        expect(sorted_dates).to eq [1935, 1941, 1945]
      end
    end

    context 'when the date field is empty' do
      let(:dates) { nil }
      it { is_expected.to eq [] }
    end

    context 'with an unparseable value' do
      let(:unparseable) { '[between 1928-1939]' }
      let(:dates) { ['1953', unparseable] }
      let(:parsed_dates) { subject }

      it 'returns the years that it can parse' do
        expect(parsed_dates).to eq [1953]
      end
    end

    context 'ranges of dates' do
      let(:dates) { ['1937/1939', '1942/1943'] }
      it { is_expected.to eq [1937, 1938, 1939, 1942, 1943] }
    end

    context 'date ranges that aren\'t just years' do
      let(:dates) { '1934-06/1934-07' }
      it { is_expected.to eq [1934] }
    end

    context 'duplicate years' do
      let(:dates) { ['1934-06/1935-07', '1934-06-01', '1934'] }
      let(:parsed_dates) { subject }

      it 'removes duplcates from the list' do
        expect(parsed_dates).to eq [1934, 1935]
      end
    end
  end
end
