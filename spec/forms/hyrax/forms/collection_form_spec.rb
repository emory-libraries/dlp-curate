# frozen_string_literal: true
# [Hyrax-overwrite-v3.3.0]
require 'rails_helper'

RSpec.describe Hyrax::Forms::CollectionForm, skip: !(Hyrax.config.collection_class < ActiveFedora::Base) do
  describe "#terms" do
    subject { described_class.terms }

    it do
      is_expected.to eq [:title, :holding_repository, :administrative_unit, :creator,
                         :contributors, :abstract, :primary_language, :finding_aid_link,
                         :institution, :local_call_number, :keywords, :subject_topics,
                         :subject_names, :subject_geo, :subject_time_periods, :notes,
                         :rights_documentation, :sensitive_material, :internal_rights_note,
                         :contact_information, :staff_notes, :system_of_record_ID,
                         :emory_ark, :visibility, :thumbnail_id, :alt_title, :source_collection_id,
                         :deposit_collection_ids]
    end
  end

  let(:collection) { FactoryBot.build(:collection_lw) }
  let(:ability) { Ability.new(FactoryBot.create(:user)) }
  let(:repository) { double }
  let(:form) { described_class.new(collection, ability, repository) }

  describe "#primary_terms" do
    subject { form.primary_terms }

    it { is_expected.to eq([:title, :holding_repository, :creator, :abstract]) }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it do
      is_expected.to eq [
        :administrative_unit, :contributors, :primary_language, :finding_aid_link,
        :institution, :local_call_number, :keywords, :subject_topics, :subject_names,
        :subject_geo, :subject_time_periods, :notes, :rights_documentation, :sensitive_material,
        :internal_rights_note, :contact_information, :staff_notes, :system_of_record_ID,
        :emory_ark, :alt_title, :source_collection_id, :deposit_collection_ids
      ]
    end
  end

  describe '#display_additional_fields?' do
    subject { form.display_additional_fields? }

    context 'with no secondary terms' do
      before do
        allow(form).to receive(:secondary_terms).and_return([])
      end
      it { is_expected.to be false }
    end
    context 'with secondary terms' do
      before do
        allow(form).to receive(:secondary_terms).and_return([:foo, :bar])
      end
      it { is_expected.to be true }
    end
  end

  describe "#id" do
    subject { form.id }

    it { is_expected.to be_nil }
  end

  describe "#required?" do
    subject { form.required?(:title) }

    it { is_expected.to be true }
  end

  describe "#human_readable_type" do
    subject { form.human_readable_type }

    it { is_expected.to eq 'Collection' }
  end

  describe "#member_ids" do
    subject { form.member_ids }
    before do
      allow(collection).to receive(:member_ids).and_return(['9999'])
    end

    it { is_expected.to eq ['9999'] }
  end

  describe ".build_permitted_params" do
    subject { described_class.build_permitted_params }

    it do
      is_expected.to eq [{ title: [] }, { holding_repository: [] }, { administrative_unit: [] },
                         { creator: [] }, { contributors: [] }, :abstract, :primary_language,
                         :finding_aid_link, :institution, :local_call_number, { keywords: [] },
                         { subject_topics: [] }, { subject_names: [] }, { subject_geo: [] },
                         { subject_time_periods: [] }, { notes: [] }, :rights_documentation,
                         :sensitive_material, :internal_rights_note, :contact_information,
                         { staff_notes: [] }, :system_of_record_ID, { emory_ark: [] },
                         :visibility, :thumbnail_id, { alt_title: [] }, :source_collection_id,
                         { deposit_collection_ids: [] },
                         { permissions_attributes: [:type, :name, :access, :id, :_destroy] }]
    end
  end
end
