require 'rails_helper'

RSpec.describe Curate::CollectionType, type: :model do
  let(:collection_type) { described_class.new }

  it "is named Library Collection" do
    expect(collection_type.title).to eq "Library Collection"
  end

  it "has nesting enabled" do
    expect(collection_type.nestable?).to eq true
  end

  it "is brandable" do
    expect(collection_type.brandable?).to eq true
  end

  it "is discoverable" do
    expect(collection_type.discoverable?).to eq true
  end

  it "is sharable" do
    expect(collection_type.sharable).to eq true
  end

  it "has share_applies_to_new_works enabled" do
    expect(collection_type.share_applies_to_new_works?).to eq true
  end

  it "has multiple membership disabled" do
    expect(collection_type.allow_multiple_membership?).to eq false
  end

  it "has default settings for everything else" do
    expect(collection_type.require_membership).to eq false
    expect(collection_type.assigns_workflow?).to eq false
    expect(collection_type.assigns_visibility?).to eq false
  end
end
