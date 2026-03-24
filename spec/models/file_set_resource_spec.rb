# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileSetResource do
  subject(:file_set) { described_class.new }

  %w[
    pcdm_use
    file_type
    deduplication_key
    preservation_event_ids
  ].each do |attr|
    include_examples('checks model for new attribute response', attr)
  end

  describe 'constants' do
    it 'defines PRIMARY' do
      expect(described_class::PRIMARY).to eq('Primary Content')
    end

    it 'defines SUPPLEMENTAL' do
      expect(described_class::SUPPLEMENTAL).to eq('Supplemental Content')
    end

    it 'defines PRESERVATION' do
      expect(described_class::PRESERVATION).to eq('Supplemental Preservation')
    end
  end

  describe '#pcdm_use' do
    it 'is single-valued' do
      file_set.pcdm_use = 'Primary Content'
      expect(file_set.pcdm_use).to eq('Primary Content')
    end
  end

  describe '#file_type' do
    it 'is single-valued' do
      file_set.file_type = 'image/tiff'
      expect(file_set.file_type).to eq('image/tiff')
    end
  end

  describe '#deduplication_key' do
    it 'is single-valued' do
      file_set.deduplication_key = 'abc123'
      expect(file_set.deduplication_key).to eq('abc123')
    end
  end

  describe '#preservation_event_ids' do
    it 'is multi-valued' do
      file_set.preservation_event_ids = ['event1', 'event2']
      expect(file_set.preservation_event_ids).to contain_exactly('event1', 'event2')
    end
  end
end
