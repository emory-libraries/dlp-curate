# frozen_string_literal: true
# [Hyrax-overwrite-v3.0.2] Brings in just the tests affected by the change
# in behavior of the #total_viewable_items method.
require 'rails_helper'

RSpec.describe Hyrax::CollectionPresenter, :clean do
  let(:user) { FactoryBot.create(:user) }
  let(:collection) { FactoryBot.build(:public_collection_lw, user: user, with_permission_template: true) }
  let(:ability) { instance_double(Ability) }
  let(:presenter) { described_class.new(solr_doc, ability) }
  let(:solr_doc) { SolrDocument.new(collection.to_solr) }

  describe "#total_viewable_items", :clean_repo do
    subject { presenter.total_viewable_items }

    before do
      allow(ability).to receive(:user_groups).and_return(['public'])
      allow(ability).to receive(:current_user).and_return(user)
    end

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private work" do
      let!(:work) { FactoryBot.create(:private_work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work" do
      let!(:work) { FactoryBot.create(:public_work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public collection" do
      let!(:subcollection) { FactoryBot.create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:work) { FactoryBot.create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { FactoryBot.create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 2 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#source/deposit related methods" do
    let(:deposit_collection) { FactoryBot.build(:public_collection_lw, user: user, with_permission_template: true) }

    before do
      collection.save!
      deposit_collection.source_collection_id = collection.id
      deposit_collection.save!
      collection.deposit_collection_ids = [deposit_collection.id]
      collection.save!
    end

    context '#deposit_collection?' do
      it 'provides right response based on source_collection_id' do
        solr_doc = SolrDocument.new(deposit_collection.to_solr)
        deposit_presenter = described_class.new(solr_doc, ability)

        expect(deposit_presenter.deposit_collection?).to be_truthy
        expect(presenter.deposit_collection?).to be_falsey
      end
    end

    context '#source_collection_object' do
      it 'provides hash built from 2 solr_doc fields' do
        solr_doc = SolrDocument.new(deposit_collection.to_solr)
        deposit_presenter = described_class.new(solr_doc, ability)

        expect(deposit_presenter.source_collection_object).to eq({ id: collection.id, title: "Testing Collection" })
      end
    end

    context '#deposit_collection_ids' do
      it 'provides array of deposit collection ids for a source collection' do
        solr_doc = SolrDocument.new(collection.to_solr)
        collection_presenter = described_class.new(solr_doc, ability)

        expect(collection_presenter.deposit_collection_ids).to eq([deposit_collection.id])
      end
    end

    context 'deposit_collections' do
      it 'provides array of deposit collection objects for a source collection' do
        solr_doc = SolrDocument.new(collection.to_solr)
        collection_presenter = described_class.new(solr_doc, ability)

        expect(collection_presenter.deposit_collections).to eq([{ id: deposit_collection.id, title: deposit_collection.title.first }])
      end
    end
  end
end
