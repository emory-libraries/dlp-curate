# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Bulkrax::ValkyrieObjectFactory, '.add_resource_to_collection' do
  let(:collection) { CollectionResource.new(id: Valkyrie::ID.new('peel-collection')) }
  let(:user) { instance_double(User) }

  before do
    allow(described_class).to receive(:find).with(resource.id).and_return(resource)
    allow(described_class).to receive(:save!) { |resource:, **| resource }
    allow(Curate::CollectionSharingService).to receive(:share_with_saved)
  end

  context 'with a work' do
    let(:resource) { CurateGenericWorkResource.new(id: Valkyrie::ID.new('work-1')) }

    it "adds it to the collection and gives it the collection's sharing" do
      described_class.add_resource_to_collection(collection:, resource:, user:)

      expect(resource.member_of_collection_ids).to eq [collection.id]
      expect(Curate::CollectionSharingService).to have_received(:share_with_saved).with(resource)
    end
  end

  context 'with a nested collection' do
    let(:resource) { CollectionResource.new(id: Valkyrie::ID.new('child-collection')) }

    it 'does not share the parent collection with it' do
      described_class.add_resource_to_collection(collection:, resource:, user:)

      expect(Curate::CollectionSharingService).not_to have_received(:share_with_saved)
    end
  end
end
