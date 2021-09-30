# frozen_string_literal: true
# [Hyrax-overwrite-v3.1.0] Brings in just the tests affected by the change
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

  describe "#total_items", :clean_repo do
    context "empty collection" do
      let(:ability) { double(::Ability, user_groups: ['public'], current_user: user) }
      let(:user) { FactoryBot.create(:user) }
      let(:collection) { FactoryBot.create(:collection_lw) }

      before { allow(ability).to receive(:admin?).and_return(false) }

      it 'returns 0' do
        expect(presenter.total_items).to eq 0
      end
    end

    context "collection with works" do
      let(:collection) { FactoryBot.create(:collection_lw) }
      let!(:work) { FactoryBot.create(:work, member_of_collections: [collection]) }

      it 'returns 1' do
        expect(presenter.total_items).to eq 1
      end
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), nil) }

      it 'returns 0' do
        expect(presenter.total_items).to eq 0
      end
    end
  end


  describe "#total_viewable_works", :clean_repo do
    subject { presenter.total_viewable_works }
    let(:ability) { double(::Ability, user_groups: ['public'], current_user: user) }
    let(:user) { FactoryBot.create(:user) }
    let(:collection) { FactoryBot.create(:collection_lw) }
    let(:solr_hash) { collection.to_solr }

    before { allow(ability).to receive(:admin?).and_return(false) }

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private work" do
      let!(:work) { FactoryBot.create(:private_work, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public work" do
      let!(:work) { FactoryBot.create(:public_work, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:work) { FactoryBot.create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { FactoryBot.create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "#total_viewable_collections", :clean_repo do
    subject { presenter.total_viewable_collections }
    let(:ability) { double(::Ability, user_groups: ['public'], current_user: user) }
    let(:user) { FactoryBot.create(:user) }
    let(:collection) { FactoryBot.create(:collection_lw) }
    let(:solr_hash) { collection.to_solr }

    before { allow(ability).to receive(:admin?).and_return(false) }

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with private collection" do
      let!(:subcollection) { FactoryBot.build(:private_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 0 }
    end

    context "collection with public collection" do
      let!(:subcollection) { FactoryBot.create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "collection with public work and sub-collection" do
      let!(:work) { FactoryBot.create(:public_work, member_of_collections: [collection]) }
      let!(:subcollection) { FactoryBot.create(:public_collection_lw, member_of_collections: [collection]) }

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

      it { is_expected.to eq 0 }
    end
  end

  describe "banner_file" do
    let(:solr_doc) { SolrDocument.new(id: '123') }

    let(:banner_info) do
      CollectionBrandingInfo.new(
        collection_id: "123",
        filename: "banner.gif",
        role: "banner",
        target_url: ""
      )
    end

    let(:logo_info) do
      CollectionBrandingInfo.new(
        collection_id: "123",
        filename: "logo.gif",
        role: "logo",
        alt_txt: "This is the logo",
        target_url: "http://logo.com"
      )
    end

    it "banner check" do
      tempfile = Tempfile.new('my_file')
      banner_info.save(tempfile.path)
      expect(presenter.banner_file).to eq("/branding/123/banner/banner.gif")
    end

    it "logo check" do
      tempfile = Tempfile.new('my_file')
      logo_info.save(tempfile.path)
      expect(presenter.logo_record).to eq([{ file: "logo.gif", file_location: "/branding/123/logo/logo.gif", alttext: "This is the logo", linkurl: "http://logo.com" }])
    end
  end
end
