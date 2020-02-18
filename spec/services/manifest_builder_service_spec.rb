# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestBuilderService do
  let(:identifier) { '508hdr7srq-cor' }
  let(:service) { described_class.new(identifier) }
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.create(:public_generic_work, id: identifier) }
  let(:solr_document) { SolrDocument.new(attributes) }
  # let(:manifest_file) { IO.read(fixture_path + '/manifest_fixture.json') }
  let(:attributes) do
    { "id" => identifier,
      "title_tesim" => ['foo', 'bar'],
      "human_readable_type_tesim" => ["Curate Generic Work"],
      "has_model_ssim" => ["CurateGenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "date_modified_dtsi" => "2019-11-11T18:20:32Z",
      "depositor_tesim" => user.uid }
  end

  context "returning a iiif manifest" do
    before do
      allow(SolrDocument).to receive(:find).and_return(solr_document)
    end

    it 'generates a iiif presentation manifest' do
      response_values = JSON.parse(service.manifest)
      expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
    end

    it 'can be called at the class level' do
      response_values = JSON.parse(described_class.build_manifest(identifier))
      expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
    end
  end
end
