# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FormatLabelService do
  let(:uri) { 'http://id.loc.gov/vocabulary/resourceTypes/aud' }
  let(:service) { described_class.instance }

  describe 'getting the label' do
    it 'provides a string when given a URI' do
      expect(service.label(uri: uri)).to eq('Audio')
    end
  end
end
