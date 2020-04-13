# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifController, type: :controller, clean: true, iiif: true do
  let(:identifier) { "508hdr7srt-cor" }
  let(:work_id) { "508hdr7srt-cor" }
  let(:image_sha) { "d28c5b20cf9b9663181d02b5ce90fac59fa666d7" }
  let(:region) { "full" }
  let(:size) { "full" }
  let(:rotation) { 0 }
  let(:quality) { "default" }
  let(:format) { "jpg" }
  let(:params) do
    {
      identifier: image_sha,
      region:     region,
      size:       size,
      rotation:   rotation,
      quality:    quality,
      format:     format
    }
  end
  let(:attributes) do
    { "id" => work_id,
      "sha1_tesim" => ["urn:sha1:#{image_sha}"],
      "visibility_ssi" => "open" }
  end

  before do
    ENV['IIIF_MANIFEST_CACHE'] = Rails.root.join('tmp').to_s
    ENV['PROXIED_IIIF_SERVER_URL'] = 'http://127.0.0.1:8182/iiif/2'
    stub_request(:any, /127.0.0.1:8182/).to_return(
      body:    "SUCCESS",
      status:  200,
      headers: { 'Content-Length' => 3 }
    )
    solr = Blacklight.default_index.connection
    solr.add([attributes])
    solr.commit
  end

  describe 'a request for a thumbnail' do
    it "returns thumbnails as expected" do
      skip("Note that thumbnails are tested in spec/requests/thumbnail_requests_spec.rb")
    end
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
    before do
      ENV['IIIF_MANIFEST_CACHE'] = Rails.root.join('tmp').to_s
      ENV['PROXIED_IIIF_SERVER_URL'] = 'https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2'
      stub_request(:get, "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/7f15795a197b389f6f2b0cb28362f777e1378f6f/info.json")
        .with(
          headers: {
            'Connection' => 'close',
            'Host' => 'iiif-cor-arch.library.emory.edu',
            'User-Agent' => 'http.rb/4.3.0'
          }
        )
        .to_return(
          status:  200,
          body:    info_dot_json_from_cantaloupe,
          headers: {}
        )
    end
    around do |example|
      ENV['IIIF_SERVER_URL'] = 'https://curate.library.emory.edu/iiif/2'
      example.run
      ENV['IIIF_SERVER_URL'] = nil
    end
    let(:image_sha) { "7f15795a197b389f6f2b0cb28362f777e1378f6f" }
    let(:params) do
      {
        identifier: image_sha,
        info:       "info",
        format:     "json"
      }
    end
    let(:info_dot_json_from_cantaloupe) do
      File.open(Rails.root.join("spec", "fixtures", "iiif_responses", "info.json")).read
    end
    let(:expected_iiif_url) { 'https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/7f15795a197b389f6f2b0cb28362f777e1378f6f/info.json' }
    it "constructs the info.json url correctly" do
      get :info, params: params
      expect(assigns(:iiif_url)).to eq expected_iiif_url
      expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
    end

    it "returns valid json" do
      get :info, params: params
      expect(assigns(:info_original)).not_to be nil
      parsed_json_orig = JSON.parse(assigns(:info_original))
      expect(parsed_json_orig["@id"]).to eq 'https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/7f15795a197b389f6f2b0cb28362f777e1378f6f'
    end

    it "changes json from Cantaloupe to have the public iiif url" do
      get :info, params: params
      expect(assigns(:info_public_iiif)).not_to be nil
      parsed_json_public = JSON.parse(assigns(:info_public_iiif))
      expect(parsed_json_public["@id"]).to eq 'https://curate.library.emory.edu/iiif/2/7f15795a197b389f6f2b0cb28362f777e1378f6f'
    end
  end

  describe "a request for a public object" do
    let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{image_sha}/full/full/0/default.jpg" }
    let(:attributes) do
      { "id" => "85370rxwg2-cor",
        "sha1_tesim" => ["urn:sha1:#{image_sha}"],
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
      { "id" => "85370rxwg2-cor",
        "sha1_tesim" => ["urn:sha1:#{image_sha}"],
        "visibility_ssi" => "low_res" }
    end

    before do
      solr = Blacklight.default_index.connection
      solr.add([attributes])
      solr.commit
    end

    context "a request for full size" do
      let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{image_sha}/full/,400/0/default.jpg" }
      let(:size) { "full" }
      it "alters a full size iiif request to ensure a low resolution image" do
        get :show, params: params
        expect(assigns(:iiif_url)).to eq expected_iiif_url
        expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
      end
    end

    context "a request for anything smaller than the full size" do
      let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{image_sha}/full/,300/0/default.jpg" }
      let(:size) { ",300" }
      it "does not alter the iiif request" do
        get :show, params: params
        expect(assigns(:iiif_url)).to eq expected_iiif_url
        expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
      end
    end

    context "a request for anything larger than max size" do
      let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{image_sha}/full/,400/0/default.jpg" }
      let(:size) { "800," }
      it "alters a full size iiif request to ensure a low resolution image" do
        get :show, params: params
        expect(assigns(:iiif_url)).to eq expected_iiif_url
        expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
      end
    end

    context "a request for anything larger than max region" do
      let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{image_sha}/0,0,800,800/,400/0/default.jpg" }
      let(:region) { "0,0,600,600" }
      it "alters the iiif request to what is permitted" do
        get :show, params: params
        expect(assigns(:iiif_url)).to eq expected_iiif_url
        expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
      end
    end

    context "a request for anything smaller than max region" do
      let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{image_sha}/12,12,800,800/,400/0/default.jpg" }
      let(:region) { "12,12,200,250" }
      it "does not alter the iiif region param" do
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
    let(:sf)            { File.open(fixture_path + '/book_page/0003_service.jpg') }
    let(:solr_document) { SolrDocument.new(attributes) }
    let(:cache_file)    { Rails.root.join('tmp', "2019-11-11_18-20-32_#{identifier}") }
    let(:attributes) do
      { "id" => identifier,
        "title_tesim" => [work.title.first],
        "human_readable_type_tesim" => ["Curate Generic Work"],
        "has_model_ssim" => ["CurateGenericWork"],
        "date_created_tesim" => ['an unformatted date'],
        "date_modified_dtsi" => "2019-11-11T18:20:32Z",
        "depositor_tesim" => 'example_user',
        "holding_repository_tesim" => ["test holding repo"],
        "rights_statement_tesim" => ["example.com"] }
    end
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
      Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
      Hydra::Works::AddFileToFileSet.call(file_set, sf, :service_file)
      work.ordered_members << file_set
      work.save!
      allow(SolrDocument).to receive(:find).and_return(solr_document)
      ENV['LUX_BASE_URL'] = 'https://example.com'
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
      expect(response_values).to include "metadata"
      expect(response_values["metadata"][0]["label"]).to eq "Provided by"
      expect(response_values["metadata"][0]["value"]).to eq ["test holding repo"]
      expect(response_values["metadata"][1]["label"]).to eq "Rights Status"
      expect(response_values["metadata"][1]["value"]).to eq ["example.com"]
      expect(response_values["metadata"][2]["label"]).to eq "Identifier"
      expect(response_values["metadata"][2]["value"]).to eq work.id
      expect(response_values["metadata"][3]["label"]).to eq "Persistent URL"
      expect(response_values["metadata"][3]["value"]).to eq "<a href=\"https://example.com/purl/#{work.id}\">https://example.com/purl/#{work.id}</a>"
      expect(response_values).to include "sequences"
      expect(response_values["sequences"].first["@type"]).to include "sc:Sequence"
      expect(response_values["sequences"].first["@id"]).to include "/iiif/#{work.id}/manifest/sequence/normal"
      expect(response_values["sequences"].first["canvases"].first["@id"]).to include "/iiif/#{work.id}/manifest/canvas/#{file_set.id}"
      expect(response_values["sequences"].first["canvases"].first["images"].first["resource"]["@id"]).to include(
        "/images/#{file_set.id}%2Ffiles%2F#{file_set.service_file.id.split('/').last}/full/600,/0/default.jpg"
      )
    end
  end
end
