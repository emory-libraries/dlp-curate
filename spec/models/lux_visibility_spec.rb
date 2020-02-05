# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work CurateGenericWork`
require 'rails_helper'

RSpec.describe "visibility and access restrictions for lux", :clean do
  let(:ability)    { ::Ability.new(FactoryBot.create(:user)) }
  let(:attributes) { {} }
  let(:env)        { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:actor_stack_work) do
    Hyrax::CurationConcern.actor.create(env)
  end

  context "when an object is marked as Private in Curate" do
    let(:work) { FactoryBot.build(:work) }
    it "does not have a read access group, because it should not be visible in Lux" do
      actor_stack_work
      work.reload
      expect(work.to_solr["edit_access_group_ssim"]).to contain_exactly "admin"
      expect(work.to_solr["read_access_group_ssim"]).to eq nil
    end
  end

  # This is the badge called "Public" in the UI
  context "when an object is marked as Public in Curate" do
    let(:work) { FactoryBot.build(:public_work) }
    it "is visible to unauthenticated users in Lux" do
      actor_stack_work
      work.reload
      expect(work.to_solr["edit_access_group_ssim"]).to contain_exactly "admin"
      expect(work.to_solr["read_access_group_ssim"]).to contain_exactly "public"
    end
  end

  # This is the badge called "Public Low View" in the UI
  context "when an object is marked as Public Low View in Curate" do
    let(:work) { FactoryBot.build(:public_low_work) }
    it "is visible to unauthenticated users in Lux" do
      actor_stack_work
      work.reload
      expect(work.to_solr["edit_access_group_ssim"]).to contain_exactly "admin"
      expect(work.to_solr["read_access_group_ssim"]).to contain_exactly "public"
    end
  end

  # This is the badge called "Emory Low Download" in the UI
  context "when an object is marked as Emory Low Download in Curate" do
    let(:work) { FactoryBot.build(:emory_low_work) }
    it "is visible to registered users in Lux" do
      actor_stack_work
      work.reload
      expect(work.to_solr["edit_access_group_ssim"]).to contain_exactly "admin"
      expect(work.to_solr["read_access_group_ssim"]).to contain_exactly "registered"
    end
  end

  # The "Emory High Download" category in the UI is the repurposed "Authenticated" category for registered users
  context "when an object is marked as Emory High Download in Curate" do
    let(:work) { FactoryBot.build(:emory_high_work) }
    it "is visible to registered users in Lux" do
      actor_stack_work
      work.reload
      expect(work.to_solr["edit_access_group_ssim"]).to contain_exactly "admin"
      expect(work.to_solr["read_access_group_ssim"]).to contain_exactly "registered"
    end
  end
end
