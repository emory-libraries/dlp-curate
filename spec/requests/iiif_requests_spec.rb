
# frozen_string_literal: true
require "rails_helper"
include Warden::Test::Helpers

RSpec.describe "IIIF requests", :clean, type: :request do
  let(:public_work_id) { "658pc866ww-cor" }
  let(:work_id) { "436tx95xcc-cor" }
  let(:public_image_sha) { "465c0075481fe4badc58c76fba42161454a18d1f" }
  let(:image_sha) { "79276774f3dbfbd977d39065eec14aa185b5213d" }
  let(:region) { "full" }
  let(:size) { "full" }
  let(:rotation) { 0 }
  let(:quality) { "default" }
  let(:format) { "jpg" }
  # let(:params) do
  #   {
  #     identifier: image_sha,
  #     region:     region,
  #     size:       size,
  #     rotation:   rotation,
  #     quality:    quality,
  #     format:     format
  #   }
  # end

  before do
    ENV['IIIF_MANIFEST_CACHE'] = Rails.root.join('tmp').to_s
    ENV['PROXIED_IIIF_SERVER_URL'] = 'https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2'
    ENV['LUX_BASE_URL'] = "127.0.0.1:3001"
  end

  describe "GET image" do
    context "with a public object" do
      let(:attributes) do
        { "id" => public_work_id,
          "digest_ssim" => ["urn:sha1:#{public_image_sha}"],
          "visibility_ssi" => "open" }
      end

      before do
        solr = Blacklight.default_index.connection
        solr.add([attributes])
        solr.commit
      end

      it "responds with a success status" do
        stub_request(:get, "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/465c0075481fe4badc58c76fba42161454a18d1f/full/full/0/default.jpg")
          .with(
            headers: {
              'Connection' => 'close',
              'Host' => 'iiif-cor-arch.library.emory.edu',
              'User-Agent' => 'http.rb/4.3.0'
            }
          )
          .to_return(status: 200, body: "", headers: {})
        get "/iiif/2/#{public_image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
        expect(response.status).to eq 200
      end
    end
    context "with an Emory High Download object" do
      let(:attributes) do
        { "id" => work_id,
          "digest_ssim" => ["urn:sha1:#{image_sha}"],
          "visibility_ssi" => "authenticated" }
      end
      let(:key) { Rails.application.secrets.shared_cookie_key }
      let(:crypt) { ActiveSupport::MessageVerifier.new(key) }

      before do
        solr = Blacklight.default_index.connection
        solr.add([attributes])
        solr.commit
        cookies[@cookies] = { "bearer_token" => "BAhJIiNUaGlzIHVzZXIgYXV0aGVudGljYXRlZCBpbiBMdXgGOgZFVA==--2cf86cbc97dd0047935010fd4e1f28b67a32251d" }
      end
      it "has cookies" do
        stub_request(:get, "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/79276774f3dbfbd977d39065eec14aa185b5213d/full/full/0/default.jpg")
          .with(
            headers: {
              'Connection' => 'close',
              'Host' => 'iiif-cor-arch.library.emory.edu',
              'User-Agent' => 'http.rb/4.3.0'
            }
          )
          .to_return(status: 200, body: "", headers: {})
        get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
        expect(response.status).to eq 200
        expect(cookies[@cookies]).to include "bearer_token"
        expect(ActiveSupport::MessageVerifier.new(key).verify(cookies[@cookies])).to eq "This user authenticated in Lux"
      end
    end
  end
  # describe "GET manifest" do
  #   context "with a public object" do
  #     it "responds with a success status" do
  #       get "/iiif/"
  #     end
  #   end
  # end
end
