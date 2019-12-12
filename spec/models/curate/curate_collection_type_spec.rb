# frozen_string_literal: true

require 'rails_helper'

# Goal: Easily create Collection objects that follow the template laid out by this
# CollectionType created by Emily:
# => #<Hyrax::CollectionType id: 3, title: "Library Collection",
# description: "Library staff-curated collections", machine_id: "library_collection",
# nestable: true, discoverable: true, sharable: true, allow_multiple_membership: false,
# require_membership: false, assigns_workflow: false, assigns_visibility: false,
# share_applies_to_new_works: true, brandable: true, badge_color: "#663333">

RSpec.describe Curate::CollectionType, :clean, type: :model do
  let(:collection_type) { described_class.new }

  it "we can find or create it easily and it won't proliferate" do
    expect(Curate::CollectionType.count).to eq 0
    Curate::CollectionType.find_or_create_library_collection_type
    expect(Curate::CollectionType.count).to eq 1
    Curate::CollectionType.find_or_create_library_collection_type
    expect(Curate::CollectionType.count).to eq 1
  end

  it 'only allows users with the admin role to manage' do
    # It does not have Registered Users group in the Creators role
    ct = Curate::CollectionType.find_or_create_library_collection_type
    collection_type_participants = Hyrax::CollectionTypeParticipant.where(hyrax_collection_type_id: ct.id)
    expect(collection_type_participants.size).to eq 1
    expect(collection_type_participants.first.agent_id).to eq "admin"
    expect(collection_type_participants.first.access).to eq "manage"
  end

  it "is named Library Collection" do
    expect(collection_type.title).to eq "Library Collection"
  end

  it 'has a description' do
    expect(collection_type.description).to eq "Library staff curated collections"
  end

  it 'has a machine_id' do
    expect(collection_type.machine_id).to eq "library_collection"
  end

  it 'has a specific badge color' do
    expect(collection_type.badge_color).to eq "#663333"
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
