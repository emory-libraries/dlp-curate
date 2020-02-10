# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'viewing an IIIF manifest', type: :system do
  let(:ability)    { ::Ability.new(FactoryBot.create(:user)) }
  let(:attributes) { {} }
  let(:env)        { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:actor_stack_work) do
    Hyrax::CurationConcern.actor.create(env)
  end

  context "when an object is marked as Public in Curate" do
    let(:work) { FactoryBot.build(:public_work) }
    it "has a well-formed manifest" do
      actor_stack_work
      work.reload
      visit "/concern/curate_generic_works/#{work.id}/manifest"
      expect(page.response_headers["Content-Type"]).to eq "application/json; charset=utf-8"
    end
  end
end
