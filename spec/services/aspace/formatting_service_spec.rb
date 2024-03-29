# frozen_string_literal: true

require 'rails_helper'

describe Aspace::FormattingService do
  let(:formatter) { described_class.new }
  let(:service) { Aspace::ApiService.new }

  before do
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_PUBLIC_BASE_URL').and_return('aspace_public_base_url')
  end

  describe '#format_resource' do
    let(:resource) { { title: "William Levi Dawson papers", primary_language: "eng", uri: "/repositories/7/resources/5687" } }
    let(:formatted_data) { formatter.format_resource(resource) }

    it 'formats primary_language' do
      expect(formatted_data[:primary_language]).to eq 'English'
    end

    it 'formats system_of_record_id' do
      expect(formatted_data[:system_of_record_id]).to eq 'aspace:/repositories/7/resources/5687'
    end

    it 'formats finding_aid_link' do
      expect(formatted_data[:finding_aid_link]).to eq 'aspace_public_base_url/repositories/7/resources/5687'
    end
  end

  describe '#format_repository' do
    let(:repository) do
      {
        repository_id:       '2',
        name:                "Pitts Special Collections and Archives",
        administrative_unit: "Pitts Special Collections and Archives",
        holding_repository:  "Pitts Special Collections and Archives"
      }
    end
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
        expect(formatter.format_holding_repository('2')).to eq 'Pitts Theology Library'
      end
    end

    context 'when value is not valid' do
      it 'returns empty string' do
        expect(formatter.format_holding_repository('10')).to eq ''
      end
    end
  end

  describe '#format_administrative_unit' do
    context 'when value is valid' do
      it 'returns Curate vocabulary value' do
        expect(formatter.format_administrative_unit('3')).to eq 'Emory University Archives'
      end
    end

    context 'when value is not valid' do
      it 'returns empty string' do
        expect(formatter.format_administrative_unit('5')).to eq ''
      end
    end
  end
end
