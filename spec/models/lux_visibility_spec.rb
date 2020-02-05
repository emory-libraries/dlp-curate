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

  context "when an object is marked as private in Curate" do
    let(:work)       { FactoryBot.build(:work) }
    it "has a Solr " do
      actor_stack_work
      work.reload
      expect(work.to_solr["edit_access_group_ssim"]).to contain_exactly "admin"
    end
  end

  context "when an object is marked as Public in Curate" do
    let(:work)       { FactoryBot.build(:public_work) }
    it "has a Solr field" do
      actor_stack_work
      work.reload
      expect(work.to_solr["edit_access_group_ssim"]).to contain_exactly "admin"
      expect(work.to_solr["read_access_group_ssim"]).to contain_exactly "public"
    end
  end
end
