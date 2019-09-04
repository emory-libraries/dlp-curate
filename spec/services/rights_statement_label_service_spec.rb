# frozen_string_literal: true
require 'rails_helper'

RSpec.describe RightsStatementLabelService do
  let(:uri) { 'http://rightsstatements.org/vocab/InC/1.0/' }
  let(:service) { described_class.instance }

  describe 'getting the label' do
    it 'provides a string when given a URI' do
      expect(service.label(uri: uri)).to eq('In Copyright')
    end
  end
end
