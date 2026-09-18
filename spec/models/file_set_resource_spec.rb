# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileSetResource do
  subject(:file_set) { described_class.new }

  %w[
    pcdm_use
    file_type
    deduplication_key
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

  describe '#preservation_event' do
    let(:preservation_event) do
      PreservationEventResource.new(
        event_id:         'wecpo-cwemclk-cvrroi',
        event_type:       'type',
        initiating_user:  'default user',
        event_start:      '2010-02-02',
        event_end:        '2010-02-03',
        outcome:          'passed',
        software_version: 'ClamXav 2.1.7',
        event_details:    'special details'
      )
    end
    it 'accepts PreservationEventResource' do
      file_set.preservation_event += [preservation_event]
      expect(file_set.preservation_event).to contain_exactly(preservation_event)
    end
  end
end
