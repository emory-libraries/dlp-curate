# frozen_string_literal: true
require 'rails_helper'
require 'iiif_manifest'

RSpec.describe 'viewing an IIIF manifest', type: :system, clean: true do
  let(:ability)    { ::Ability.new(FactoryBot.create(:user)) }
  let(:attributes) { {} }
  let(:env)        { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:actor_stack_work) do
    ENV['IIIF_MANIFEST_CACHE'] = "./tmp/"
    Hyrax::CurationConcern.actor.create(env)
  end

  context "public works" do
    let(:work) { FactoryBot.build(:public_work) }
    it "has a well-formed manifest" do
      actor_stack_work
      work.reload

      # visit "/concern/curate_generic_works/#{work.id}/manifest"
      visit "/iiif/#{work.id}/manifest"

      expect(page.response_headers["Content-Type"]).to eq "application/json; charset=utf-8"

      response_values = JSON.parse(page.body)

      expect(response_values).to include "@context"
      expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
      expect(response_values).to include "@type"
      expect(response_values["@type"]).to include "sc:Manifest"
      expect(response_values).to include "@id"
      expect(response_values["@id"]).to include "/concern/curate_generic_works/#{work.id}/manifest"
      expect(response_values).to include "label"
      expect(response_values["label"]).to include work.title.first.to_s

      # for continued work: per the 2.1 Presentation API, the manifest must include sequences,
      # and the sequences must include canvases
    end
  end

  context "public_low_work" do
    let(:work) { FactoryBot.build(:public_low_work) }
    it 'allows everyone to see the manifest even if they are not authenticated' do
      actor_stack_work
      work.reload
      visit "/iiif/#{work.id}/manifest"
      expect(page.response_headers["Content-Type"]).to eq "application/json; charset=utf-8"
      response_values = JSON.parse(page.body)
      expect(response_values).to include "@context"
    end
  end
end
