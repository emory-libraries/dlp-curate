# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifController, type: :controller do
  let(:identifier) { "abc123" }
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

  describe "a request for a public object" do
    let(:expected_iiif_url) { 'http://127.0.0.1:8182/iiif/2/abc123/full/full/0/default.jpg' }

    before do
      ENV['PROXIED_IIIF_SERVER_URL'] = 'http://127.0.0.1:8182/iiif/2'
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
end
