# frozen_string_literal: true

require 'rails_helper'

describe Aspace::FormattingService do
  let(:formatter) { described_class.new }

  describe '#format_primary_language' do
    context 'when language is valid' do
      it 'returns English name' do
        expect(formatter.format_primary_language('eng')).to eq 'English'
      end
    end

    context 'when language is not valid' do
      it 'returns empty string' do
        expect(formatter.format_primary_language('invalid')).to eq ''
      end
    end
  end
end
