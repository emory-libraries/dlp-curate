# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work CurateGenericWork`
require 'rails_helper'

RSpec.describe CurateGenericWork do
  let(:ability)    { ::Ability.new(FactoryBot.create(:user)) }
  let(:attributes) { {} }
  let(:work)       { FactoryBot.build(:work, id: 'wk1', title: ['Work 1']) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:env)        { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:actor_stack_work) do
    Hyrax::CurationConcern.actor.create(env)
  end

  context "multi-part objects" do

    it 'goes through the actor stack' do
      actor_stack_work
      work.reload
      expect(work.to_solr["edit_access_group_ssim"]).to contain_exactly "admin"
    end
  end
end
