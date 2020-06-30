# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataDetails do
  let(:work_attributes) { CurateGenericWorkAttributes.instance }
  let(:metadata_details) { described_class.instance }
  let(:details) { metadata_details.details(work_attributes: work_attributes) }

  context 'for a given attribute' do
    let(:title) { details.find { |row| row[:attribute] == 'title' } }

    it 'has a predicate' do
      expect(title[:predicate]).to eq('http://purl.org/dc/terms/title')
    end

    it 'has a label' do
      expect(title[:label]).to eq('Title (title)')
    end

    it 'has a type' do
      expect(title[:type]).to eq('string')
    end

    it 'has multiple' do
      expect(title[:multiple]).to eq('true')
    end

    it 'has the validator' do
      expect(title[:validator]).to eq('required')
    end

    it 'has usage' do
      expect(title[:usage]).to include('name of the resource being described')
    end
  end

  context 'find csv headers for each field' do
    let(:date_modified) { details.find { |row| row[:attribute] == 'date_modified' } }
    let(:title) { details.find { |row| row[:attribute] == 'title' } }

    it 'finds the csv header when the field is mapped' do
      expect(title[:csv_header]).to eq('title')
    end
    it 'indicates when field is not mapped' do
      expect(date_modified[:csv_header]).to eq('not configured')
    end
  end

  it 'can produce a CSV with the right headers' do
    header = metadata_details.to_csv(work_attributes: work_attributes).lines.first
    expect(header).to include('attribute', 'predicate', 'usage')
  end

  it 'can produce a CSV with the right data' do
    access_restriction_notes = metadata_details.to_csv(work_attributes: work_attributes).lines.find { |line| line.starts_with? 'access_restriction_notes' }
    expect(access_restriction_notes).to include('Access Restrictions (access_restriction_notes)', 'http://purl.org/dc/terms/accessRights')
  end
end
