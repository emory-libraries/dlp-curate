# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::CollectionType, type: :model do
  let(:collection_type) { FactoryBot.build(:collection_type) }

  describe '.collection_type_settings_methods' do
    subject { described_class.collection_type_settings_methods }

    it { is_expected.to be_a(Array) }
  end

  describe '#collection_type_settings_methods' do
    subject { described_class.new.collection_type_settings_methods }

    it { is_expected.to be_a(Array) }
  end

  it "has basic metadata" do
    expect(collection_type).to respond_to(:title)
    expect(collection_type.title).not_to be_empty
    expect(collection_type).to respond_to(:description)
    expect(collection_type.description).not_to be_empty
    expect(collection_type).to respond_to(:machine_id)
  end

  it "has configuration properties with defaults" do
    expect(collection_type.nestable?).to eq true
    expect(collection_type.brandable?).to eq true
    expect(collection_type.discoverable?).to eq true
    expect(collection_type.sharable).to eq true
    expect(collection_type.share_applies_to_new_works?).to eq true
    expect(collection_type.allow_multiple_membership?).to eq true
    expect(collection_type.require_membership).to eq false
    expect(collection_type.assigns_workflow?).to eq false
    expect(collection_type.assigns_visibility?).to eq false
    expect(collection_type.deposit_only_collection?).to eq false
  end

  describe '#gid' do
    it 'returns the gid when id exists' do
      collection_type.id = 5
      expect(collection_type.gid.to_s).to eq 'gid://dlp-curate/hyrax-collectiontype/5'
    end

    it 'returns nil when id is nil' do
      collection_type.id = nil
      expect(collection_type.gid).to be_nil
    end
  end

  describe ".any_nestable?" do
    context "when there is a nestable collection type" do
      let(:collection_type) { FactoryBot.create(:collection_type, nestable: true) }

      it 'returns true' do
        collection_type
        expect(described_class.any_nestable?).to be true
      end
    end

    context "when there are no nestable collection types" do
      let(:collection_type) { FactoryBot.create(:collection_type, nestable: false) }

      it 'returns false' do
        collection_type
        expect(described_class.any_nestable?).to be false
      end
    end
  end

  describe ".find_or_create_default_collection_type" do
    let(:default_collection_type) { described_class.find_or_create_default_collection_type }

    it 'creates a default collection type' do
      expect(Hyrax::CollectionTypes::CreateService).to receive(:create_collection_type)
      default_collection_type
    end
  end

  describe ".find_or_create_admin_set_type" do
    let(:admin_set_type) { described_class.find_or_create_admin_set_type }

    it 'creates admin set collection type' do
      machine_id = described_class::ADMIN_SET_MACHINE_ID
      title = described_class::ADMIN_SET_DEFAULT_TITLE
      expect(Hyrax::CollectionTypes::CreateService).to receive(:create_collection_type).with(machine_id: machine_id, title: title, options: anything)
      admin_set_type
    end
  end

  describe "validations", :clean do
    let(:collection_type) { FactoryBot.create(:collection_type) }

    it "ensures the required fields have values" do
      collection_type.title = nil
      collection_type.machine_id = nil
      expect(collection_type).not_to be_valid
      expect(collection_type.errors.messages[:title]).not_to be_empty
      expect(collection_type.errors.messages[:machine_id]).not_to be_empty
    end
  end

  describe '.find_by_gid' do
    let(:collection_type) { FactoryBot.create(:collection_type) }
    let(:nonexistent_gid) { 'gid://internal/hyrax-collectiontype/NO_EXIST' }

    it 'returns instance of collection type when one with the gid exists' do
      expect(described_class.find_by_gid(collection_type.gid)).to eq collection_type
    end

    it 'returns false if collection type with gid does NOT exist' do
      expect(described_class.find_by_gid(nonexistent_gid)).to eq false
    end

    it 'returns false if gid is nil' do
      expect(described_class.find_by_gid(nil)).to eq false
    end
  end

  describe '.find_by_gid!' do
    let(:collection_type) { FactoryBot.create(:collection_type) }
    let(:nonexistent_gid) { 'gid://internal/hyrax-collectiontype/NO_EXIST' }

    it 'returns instance of collection type when one with the gid exists' do
      expect(described_class.find_by_gid(collection_type.gid)).to eq collection_type
    end

    it 'raises error if collection type with gid does NOT exist' do
      expect { described_class.find_by_gid!(nonexistent_gid) }.to raise_error(ActiveRecord::RecordNotFound, "Couldn't find Hyrax::CollectionType matching GID '#{nonexistent_gid}'")
    end

    it 'raises error if passed nil' do
      expect { described_class.find_by_gid!(nil) }.to raise_error(ActiveRecord::RecordNotFound, "Couldn't find Hyrax::CollectionType matching GID ''")
    end
  end

  describe "collections" do
    let!(:collection) { FactoryBot.create(:collection_lw, collection_type_gid: collection_type.gid.to_s) }
    let(:collection_type) { FactoryBot.create(:collection_type) }

    it 'returns collections of this collection type' do
      expect(collection_type.collections.to_a).to include collection
    end

    it 'returns empty array if gid is nil' do
      expect(Collection.count).not_to be_zero
      expect(FactoryBot.build(:collection_type).collections).to eq []
    end
  end

  describe "collections?", :clean do
    let(:collection_type) { FactoryBot.create(:collection_type) }

    it 'returns true if there are any collections of this collection type' do
      FactoryBot.create(:collection_lw, collection_type_gid: collection_type.gid.to_s)
      expect(collection_type.collections?).to eq true
    end
    it 'returns false if there are not any collections of this collection type' do
      expect(collection_type.collections?).to eq false
    end
  end

  describe "machine_id" do
    let(:collection_type) { described_class.new }

    it 'assigns machine_id on title=' do
      expect(collection_type.machine_id).to be_blank
      collection_type.title = "New Collection Type"
      expect(collection_type.machine_id).not_to be_blank
    end
  end

  describe "destroy" do
    before do
      allow(collection_type).to receive(:collections?).and_return(true)
    end

    it "fails if collections exist of this type" do
      expect(collection_type.destroy).to eq false
      expect(collection_type.errors).not_to be_empty
    end
  end

  describe "save (no settings changes)" do
    before do
      allow(collection_type).to receive(:collections?).and_return(true)
    end

    it "succeeds no changes to settings are being made" do
      expect(collection_type.save).to be true
      expect(collection_type.errors).to be_empty
    end
  end

  describe "save" do
    before do
      allow(collection_type).to receive(:changes).and_return('nestable' => false)
    end

    context 'for non-special collection type' do
      before do
        allow(collection_type).to receive(:collections?).and_return(true)
      end

      it "fails if collections exist of this type and settings are changed" do
        expect(collection_type.save).to be false
        expect(collection_type.errors.messages[:base].first).to eq "Collection type settings cannot be altered for a type that has collections"
      end
    end

    context 'for admin set collection type' do
      let(:collection_type) { FactoryBot.create(:admin_set_collection_type) }

      before do
        allow(collection_type).to receive(:collections?).and_return(false)
      end

      it 'fails if settings are changed' do
        expect(collection_type.save).to be false
        expect(collection_type.errors.messages[:base].first).to eq "Collection type settings cannot be altered for the Administrative Set type"
      end
    end

    context 'for user collection type' do
      let(:collection_type) { FactoryBot.create(:user_collection_type) }

      before do
        allow(collection_type).to receive(:collections?).and_return(false)
      end

      it 'fails if settings are changed' do
        expect(collection_type.save).to be false
        expect(collection_type.errors.messages[:base].first).to eq "Collection type settings cannot be altered for the User Collection type"
      end
    end
  end
end
