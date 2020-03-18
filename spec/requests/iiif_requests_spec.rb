
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

      let(:user) { User.from_omniauth(auth_hash) }
      let(:cookie_name) { "bearer_token" }
      let(:encrypted_cookie_value) { "43BB3AA86080214273B978723D70DE6894DB9DEAC93FB27C79799EAD405B3FE8" }
      let(:cookie) { Rack::Test::Cookie.new("#{cookie_name}=#{encrypted_cookie_value}") }

      before do
        solr = Blacklight.default_index.connection
        solr.add([attributes])
        solr.commit
        stub_request(:get, "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/79276774f3dbfbd977d39065eec14aa185b5213d/full/full/0/default.jpg")
          .with(
            headers: {
              'Connection' => 'close',
              'Host' => 'iiif-cor-arch.library.emory.edu',
              'User-Agent' => 'http.rb/4.3.0'
            }
          )
          .to_return(status: 200, body: "", headers: {})
      end

      context "a user who has authenticated in Lux" do
        before do
          # cookies << cookie
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" })
        end

        it "returns an image" do
          expect(request.cookies["bearer_token"]).to eq encrypted_cookie_value
          expect(response.status).to eq 200
        end
      end

      context "a user who has not authenticated in Lux" do
        before do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
        end

        it "does not return an image" do
          expect(response.status).to eq 403
        end
      end
    end
  end
end
