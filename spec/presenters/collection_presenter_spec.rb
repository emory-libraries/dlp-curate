# frozen_string_literal: true
# [Hyrax-overwrite-v3.0.0.pre.rc1] Brings in just the tests affected by the change
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
end
