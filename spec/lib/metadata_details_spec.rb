# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataDetails do
  let(:work_attributes) { CurateGenericWorkAttributes.instance }
  let(:metadata_details) { described_class.instance }

  it 'has a predicate' do
    expect(metadata_details.details(work_attributes: work_attributes)['title'][:predicate]).to eq("http://purl.org/dc/terms/title")
  end

  it 'has a label' do
    expect(metadata_details.details(work_attributes: work_attributes)['title'][:label]).to eq("Title")
  end

  it 'has a type' do
    expect(metadata_details.details(work_attributes: work_attributes)['title'][:type]).to eq("string")
  end

  it 'has multiple' do
    expect(metadata_details.details(work_attributes: work_attributes)['institution'][:multiple]).to eq("false")
  end

  it 'has the validator' do
    expect(metadata_details.details(work_attributes: work_attributes)['title'][:validator]).to eq("required")
  end

  context "find csv headers for each field" do
    it 'finds the csv header when the field is mapped' do
      expect(metadata_details.details(work_attributes: work_attributes)['title'][:csv_header]).to eq("title")
    end
    it 'indicates when field is not configured' do
      expect(metadata_details.details(work_attributes: work_attributes)['date_modified'][:csv_header]).to eq("not configured")
    end
  end
end
