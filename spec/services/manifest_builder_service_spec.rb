# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestBuilderService do
  let(:identifier) { '508hdr7srq-cor' }
  let(:service) { described_class.new(identifier) }
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.create(:public_generic_work, id: identifier) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:cache_file) { Rails.root.join('tmp', "2019-11-11_18-20-32_#{identifier}") }
  let(:attributes) do
    { "id" => identifier,
      "title_tesim" => [work.title.first],
      "human_readable_type_tesim" => ["Curate Generic Work"],
      "has_model_ssim" => ["CurateGenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "date_modified_dtsi" => "2019-11-11T18:20:32Z",
      "depositor_tesim" => user.uid }
  end

  context "returning a iiif manifest" do
    before do
      ENV['IIIF_MANIFEST_CACHE'] = "./tmp"
      allow(SolrDocument).to receive(:find).and_return(solr_document)
      File.delete(cache_file) if File.exist?(cache_file)
    end

    after do
      File.delete(cache_file) if File.exist?(cache_file)
    end

    it 'generates a iiif presentation manifest' do
      response_values = JSON.parse(service.manifest)
      expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
    end

    it 'can be called at the class level' do
      response_values = JSON.parse(described_class.build_manifest(identifier))
      expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
    end

    it "saves manifest file in a cache" do
      expect(File).not_to exist(cache_file)
      response_values = JSON.parse(described_class.build_manifest(identifier))
      expect(response_values).to_s.match(identifier)
      expect(File).to exist(cache_file)

      response_values = JSON.parse(File.open(cache_file).read)

      expect(response_values).to include "@context"
      expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
      expect(response_values).to include "@type"
      expect(response_values["@type"]).to include "sc:Manifest"
      expect(response_values).to include "@id"
      expect(response_values["@id"]).to include "/concern/curate_generic_works/#{work.id}/manifest"
      expect(response_values).to include "label"
      expect(response_values["label"]).to include work.title.first.to_s
    end
  end
end
