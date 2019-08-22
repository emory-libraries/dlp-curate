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

  it 'can produce a CSV with the right headers' do
    expect(metadata_details.to_csv(work_attributes: work_attributes)).to match(/attribute,predicate/)
  end

  it 'can produce a CSV with the right data' do
    expect(metadata_details.to_csv(work_attributes: work_attributes)).to match(/access_right,http:\/\/purl.org\/dc\/terms\/accessRights/)
  end
end
