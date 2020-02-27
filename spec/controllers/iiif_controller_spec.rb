# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifController, type: :controller, clean: true do
  let(:identifier) { "508hdr7srt-cor" }
  let(:region) { "full" }
  let(:size) { "full" }
  let(:rotation) { 0 }
  let(:quality) { "default" }
  let(:format) { "jpg" }
  let(:params) do
    {
      identifier: identifier,
      region:     region,
      size:       size,
      rotation:   rotation,
      quality:    quality,
      format:     format
    }
  end

  before do
    ENV['PROXIED_IIIF_SERVER_URL'] = 'http://127.0.0.1:8182/iiif/2'
    stub_request(:any, /127.0.0.1:8182/).to_return(
      body:    "SUCCESS",
      status:  200,
      headers: { 'Content-Length' => 3 }
    )
  end

  describe 'a request without the IIIF_SERVER_URL set' do
    before do
      ENV['PROXIED_IIIF_SERVER_URL'] = nil
    end
    it "raises an error" do
      expect { get :show, params: params }.to raise_exception RuntimeError
    end
  end

  describe "a request for info.json" do
    let(:params) do
      {
        identifier: identifier,
        info:       "info",
        format:     "json"
      }
    end
    let(:expected_iiif_url) { 'http://127.0.0.1:8182/iiif/2/508hdr7srt-cor/info.json' }
    it "returns as json" do
      get :info, params: params
      expect(assigns(:iiif_url)).to eq expected_iiif_url
      expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
    end
  end

  describe "a request for a public object" do
    let(:identifier) { "508hdr7srt-cor" }
    let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{identifier}/full/full/0/default.jpg" }
    let(:attributes) do
      { "id" => identifier,
        "visibility_ssi" => "open" }
    end
    before do
      solr = Blacklight.default_index.connection
      solr.add([attributes])
      solr.commit
    end

    it "does not alter the iiif request" do
      get :show, params: params
      expect(assigns(:iiif_url)).to eq expected_iiif_url
      expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
    end
  end

  describe "a request for a public low view object" do
    let(:identifier) { "508hdr7srt-cor" }
    let(:attributes) do
      { "id" => identifier,
        "visibility_ssi" => "low_res" }
    end

    before do
      solr = Blacklight.default_index.connection
      solr.add([attributes])
      solr.commit
    end

    context "a request for full size" do
      let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{identifier}/full/,400/0/default.jpg" }
      it "alters a full size iiif request to ensure a low resolution image" do
        get :show, params: params
        expect(assigns(:iiif_url)).to eq expected_iiif_url
        expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
      end
    end
  end

  describe "#manifest" do
    let(:work)          { FactoryBot.create(:public_generic_work, id: identifier) }
    let(:file_set)      { FactoryBot.create(:file_set) }
    let(:pmf)           { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
    let(:solr_document) { SolrDocument.new(attributes) }
    let(:cache_file)    { Rails.root.join('tmp', "2019-11-11_18-20-32_#{identifier}") }
    let(:attributes) do
      { "id" => identifier,
        "title_tesim" => [work.title.first],
        "human_readable_type_tesim" => ["Curate Generic Work"],
        "has_model_ssim" => ["CurateGenericWork"],
        "date_created_tesim" => ['an unformatted date'],
        "date_modified_dtsi" => "2019-11-11T18:20:32Z",
        "depositor_tesim" => 'example_user' }
    end

    before do
      Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
      work.ordered_members << file_set
      work.save!
      allow(SolrDocument).to receive(:find).and_return(solr_document)
    end

    it "saves manifest file in a cache" do
      FileUtils.rm_f("./tmp/2019-11-11_18-20-32_508hdr7srt-cor")

      get :manifest, params: params
      expect(File).to exist(cache_file)

      response_values = JSON.parse(File.open(cache_file).read)

      expect(response_values).to include "@context"
      expect(response_values["@context"]).to include "http://iiif.io/api/presentation/2/context.json"
      expect(response_values).to include "@type"
      expect(response_values["@type"]).to include "sc:Manifest"
      expect(response_values).to include "@id"
      expect(response_values["@id"]).to include "/iiif/#{work.id}/manifest"
      expect(response_values).to include "label"
      expect(response_values["label"]).to include work.title.first.to_s
      expect(response_values).to include "sequences"
      expect(response_values["sequences"].first["@type"]).to include "sc:Sequence"
      expect(response_values["sequences"].first["@id"]).to include "/iiif/#{work.id}/manifest/sequence/normal"
      expect(response_values["sequences"].first["canvases"].first["@id"]).to include "/iiif/#{work.id}/manifest/canvas/#{file_set.id}"
      expect(response_values["sequences"].first["canvases"].first["images"].first["resource"]["@id"]).to include
      "/images/#{file_set.id}%2Ffiles%2F#{file_set.files.first.id.split('/').last}/full/600,/0/default.jpg"
    end
  end
end
