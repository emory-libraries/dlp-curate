# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifController, type: :controller do
  let(:identifier) { "7e7c52437c41c0ec1982e39d93a7a32db1ed1ba7" }
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
    let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{identifier}/info.json" }

    before do
      ENV['PROXIED_IIIF_SERVER_URL'] = 'http://127.0.0.1:8182/iiif/2'
    end

    it "returns as json" do
      stub_request(:any, expected_iiif_url).to_return(
        body:    "SUCCESS",
        status:  200,
        headers: { 'Content-Length' => 3 }
      )
      get :info, params: params
      expect(assigns(:iiif_url)).to eq expected_iiif_url
    end
  end

  describe "a request for a public object" do
    let(:identifier) { "7e7c52437c41c0ec1982e39d93a7a32db1ed1ba7" }
    let(:document) do
      {
        id: '222333',
        has_model_ssim:["FileSet"],
        visibility_ssi: ['open'],
        original_checksum_tesim:["urn:md5:7bd6a1468ed28a174c928a1423dd2704",
          "urn:sha1:7e7c52437c41c0ec1982e39d93a7a32db1ed1ba7",
          "urn:sha256:041bd2ea85c0cb8a41917b99f76ae4cd27108db887ce95fe4b0c83c5b16b1ed7"]
      }
    end
    let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{identifier}/full/full/0/default.jpg" }

    before do
      ENV['PROXIED_IIIF_SERVER_URL'] = 'http://127.0.0.1:8182/iiif/2'
      delete_all_documents_from_solr
      solr = Blacklight.default_index.connection
      solr.add([document])
      solr.commit
    end

    it "does not alter the iiif request" do
      stub_request(:any, expected_iiif_url).to_return(
        body:    "SUCCESS",
        status:  200,
        headers: { 'Content-Length' => 3 }
      )
      get :show, params: params
      expect(assigns(:iiif_url)).to eq expected_iiif_url
    end
  end

  describe "a request for a Public Low View object" do

    let(:identifier) { "7e7c52437c41c0ec1982e39d93a7a32db1ed1ba7" }
    let(:document) do
      {
        id: '222333',
        has_model_ssim:["FileSet"],
        visibility_ssi: ['low_res'],
        original_checksum_tesim:["urn:md5:7bd6a1468ed28a174c928a1423dd2704",
          "urn:sha1:7e7c52437c41c0ec1982e39d93a7a32db1ed1ba7",
          "urn:sha256:041bd2ea85c0cb8a41917b99f76ae4cd27108db887ce95fe4b0c83c5b16b1ed7"]
      }
    end
    let(:expected_iiif_url) { "http://127.0.0.1:8182/iiif/2/#{identifier}/full/400,/0/default.jpg" }

    before do
      ENV['PROXIED_IIIF_SERVER_URL'] = 'http://127.0.0.1:8182/iiif/2'
      delete_all_documents_from_solr
      solr = Blacklight.default_index.connection
      solr.add([document])
      solr.commit
    end

    it "alters the iiif request to ensure a max resolution" do
      stub_request(:any, expected_iiif_url).to_return(
        body:    "SUCCESS",
        status:  200,
        headers: { 'Content-Length' => 3 }
      )
      get :show, params: params
      expect(assigns(:iiif_url)).to eq expected_iiif_url
    end
  end
end
