
# frozen_string_literal: true
require "rails_helper"
include Warden::Test::Helpers

RSpec.describe "IIIF requests", :clean, type: :request, iiif: true do
  let(:work_id) { "436tx95xcc-cor" }
  let(:image_sha) { "79276774f3dbfbd977d39065eec14aa185b5213d" }
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
  let(:cookie_name) { "bearer_token" }
  let(:encrypted_cookie_value) { "BE0F7323469F3E7DF86CF9CA95B8ADD5D17753DA4F00BB67F2A9E8EC93E6A370" }

  before do
    ENV['IIIF_MANIFEST_CACHE'] = Rails.root.join('tmp').to_s
    ENV['PROXIED_IIIF_SERVER_URL'] = 'https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2'
    ENV['LUX_BASE_URL'] = "127.0.0.1:3001"
    solr = Blacklight.default_index.connection
    solr.add([attributes])
    solr.commit
    stub_request(:any, /iiif-cor-arch.library.emory.edu/)
      .with(
        headers: {
          'Connection' => 'close',
          'Host' => 'iiif-cor-arch.library.emory.edu',
          'User-Agent' => 'http.rb/4.3.0'
        }
      )
      .to_return(status: 200, body: "I am returning an image, but for now I'm words", headers: {})
  end

  describe "GET image" do
    context "with a Public object" do
      let(:attributes) do
        { "id" => work_id,
          "digest_ssim" => ["urn:sha1:#{image_sha}"],
          "visibility_ssi" => "open" }
      end

      context "a request for anything larger than max size" do
        let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/full/#{size}/0/default.jpg" }
        let(:size) { "800," }
        it "does not alter a full size iiif request to ensure a high resolution image" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
          expect(assigns(:iiif_url)).to eq expected_iiif_url
          expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
        end
      end
    end

    context "with a Public Low View object" do
      let(:attributes) do
        { "id" => work_id,
          "digest_ssim" => ["urn:sha1:#{image_sha}"],
          "visibility_ssi" => "low_res" }
      end

      context "a request for full size" do
        let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/full/,400/0/default.jpg" }
        let(:size) { "full" }
        it "alters a full size iiif request to ensure a low resolution image" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
          expect(assigns(:iiif_url)).to eq expected_iiif_url
          expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
        end
      end

      context "a request for anything smaller than the full size" do
        let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/full/,300/0/default.jpg" }
        let(:size) { ",300" }
        it "does not alter the iiif request" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
          expect(assigns(:iiif_url)).to eq expected_iiif_url
          expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
        end
      end

      context "a request for anything larger than max size" do
        let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/full/,400/0/default.jpg" }
        let(:size) { "800," }
        it "alters a full size iiif request to ensure a low resolution image" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
          expect(assigns(:iiif_url)).to eq expected_iiif_url
          expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
        end
      end

      context "a request for anything larger than max region" do
        let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/0,0,800,800/,400/0/default.jpg" }
        let(:region) { "0,0,600,600" }
        it "alters the iiif request to what is permitted" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
          expect(assigns(:iiif_url)).to eq expected_iiif_url
          expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
        end
      end

      context "a request for anything smaller than max region" do
        let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/12,12,800,800/,400/0/default.jpg" }
        let(:region) { "12,12,200,250" }
        it "does not alter the iiif region param" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
          expect(assigns(:iiif_url)).to eq expected_iiif_url
          expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
        end
      end
    end

    context "with an Emory Low Download object" do
      let(:attributes) do
        { "id" => work_id,
          "digest_ssim" => ["urn:sha1:#{image_sha}"],
          "visibility_ssi" => "emory_low" }
      end

      context "a user who has authenticated in Lux" do
        before do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" })
        end

        it "returns an image" do
          expect(request.cookies["bearer_token"]).to eq encrypted_cookie_value
          expect(response.status).to eq 200
        end

        context "a request for full size" do
          let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/full/,400/0/default.jpg" }
          let(:size) { "full" }
          it "alters a full size iiif request to ensure a low resolution image" do
            get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" })
            expect(assigns(:iiif_url)).to eq expected_iiif_url
            expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
          end
        end

        context "a request for anything smaller than the full size" do
          let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/full/,300/0/default.jpg" }
          let(:size) { ",300" }
          it "does not alter the iiif request" do
            get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" })
            expect(assigns(:iiif_url)).to eq expected_iiif_url
            expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
          end
        end

        context "a request for anything larger than max size" do
          let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/full/,400/0/default.jpg" }
          let(:size) { "800," }
          it "alters a full size iiif request to ensure a low resolution image" do
            get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" })
            expect(assigns(:iiif_url)).to eq expected_iiif_url
            expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
          end
        end

        context "a request for anything larger than max region" do
          let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/0,0,800,800/,400/0/default.jpg" }
          let(:region) { "0,0,600,600" }
          it "alters the iiif request to what is permitted" do
            get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" })
            expect(assigns(:iiif_url)).to eq expected_iiif_url
            expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
          end
        end

        context "a request for anything smaller than max region" do
          let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/12,12,800,800/,400/0/default.jpg" }
          let(:region) { "12,12,200,250" }
          it "does not alter the iiif region param" do
            get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" })
            expect(assigns(:iiif_url)).to eq expected_iiif_url
            expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
          end
        end
      end

      context "a user who has not authenticated in Lux" do
        before do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
        end

        it "does not return an image" do
          expect(response.status).to eq 403
          expect(response.body).to be_empty
        end
      end
    end

    context "with an Emory High Download object" do
      let(:attributes) do
        { "id" => work_id,
          "digest_ssim" => ["urn:sha1:#{image_sha}"],
          "visibility_ssi" => "authenticated" }
      end

      context "a request for anything larger than max size" do
        let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/full/#{size}/0/default.jpg" }
        let(:size) { "800," }
        it "does not alter a full size iiif request to ensure a high resolution image" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" })
          expect(assigns(:iiif_url)).to eq expected_iiif_url
          expect(response.has_header?('Access-Control-Allow-Origin')).to be_truthy
        end
      end
    end
  end
end
