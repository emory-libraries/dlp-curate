# frozen_string_literal: true

require 'rails_helper'

describe Aspace::FormattingService do
  let(:formatter) { described_class.new }
  let(:service) { Aspace::ApiService.new }

  describe '#format_resource' do
    let(:resource) { { title: "William Levi Dawson papers", primary_language: "eng" } }
    let(:formatted_data) { formatter.format_resource(resource) }

    it 'formats primary language' do
      expect(formatted_data[:primary_language]).to eq 'English'
    end
  end

  describe '#format_repository' do
    let(:repository) { { name: "Pitts Special Collections and Archives", administrative_unit: "Pitts Special Collections and Archives", holding_repository: "Pitts Special Collections and Archives" } }
    let(:formatted_data) { formatter.format_repository(repository) }

    it 'formats administrative unit' do
      expect(formatted_data[:administrative_unit]).to eq ''
    end

    it 'formats holding repository' do
      expect(formatted_data[:holding_repository]).to eq 'Pitts Theology Library'
    end
  end

  describe '#format_primary_language' do
    context 'when value is valid' do
      it 'returns iso639-2 English name' do
        expect(formatter.format_primary_language('eng')).to eq 'English'
      end
    end

    context 'when value is not valid' do
      it 'returns empty string' do
        expect(formatter.format_primary_language('invalid')).to eq ''
      end
    end
  end

  describe '#format_holding_repository' do
    context 'when value is valid' do
      it 'returns Curate vocabulary value' do
        expect(formatter.format_holding_repository('Pitts Special Collections and Archives')).to eq 'Pitts Theology Library'
      end
    end

    context 'when value is not valid' do
      it 'returns empty string' do
        expect(formatter.format_holding_repository('invalid holding repository')).to eq ''
      end
    end
  end

  describe '#format_administrative_unit' do
    context 'when value is valid' do
      it 'returns Curate vocabulary value' do
        expect(formatter.format_administrative_unit('Emory University Archives')).to eq 'Emory University Archives'
      end
    end

    context 'when value is not valid' do
      it 'returns empty string' do
        expect(formatter.format_administrative_unit('invalid administrative unit')).to eq ''
      end
    end
  end
end
