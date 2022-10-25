# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManifestRegenerationController, type: :controller, clean: true do
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.create(:public_generic_work, user: user) }
  let(:ability) { instance_double(Ability) }
  let(:presenter) { Hyrax::CurateGenericWorkPresenter.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) do
    { "id" => work.id,
      "title_tesim" => [work.title.first],
      "human_readable_type_tesim" => ["Curate Generic Work"],
      "has_model_ssim" => ["CurateGenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "date_modified_dtsi" => "2019-11-11T18:20:32Z",
      "depositor_tesim" => 'example_user',
      "manifest_cache_key_tesim" => "abc123" }
  end

  context "when signed in" do
    describe "POST clean_up" do
      before do
        sign_in user
        allow(SolrDocument).to receive(:find).and_return(solr_document)
        allow(Hyrax::CurateGenericWorkPresenter).to receive(:new).and_return(presenter)
      end

      it "queues up fileset cleanup job" do
        expect(ManifestBuilderService).to receive(:regenerate_manifest).with(presenter: presenter, curation_concern: work)
        post :regen_manifest, params: { work_id: work }, xhr: true
        expect(response).to be_successful
      end
    end
  end

  context "when not signed in" do
    describe "POST clean_up" do
      it "returns 401" do
        post :regen_manifest, params: { work_id: work }, xhr: true
        expect(response.code).to eq '401'
      end
    end
  end
end
