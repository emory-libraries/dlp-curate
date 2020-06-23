
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
  let(:spoofed_cookie_value) { "DD72652691A4970E4CA56CAC403851D494841D89AD2E7493106BB96FE31E8761" }
  let(:badly_spoofed_cookie_value) { "BE0F7323469F3E7DF86CF9CA95B8ADD5D17753DA4F00BB67F2A9E8EC93E6A370" }
  let(:time_to_string) { 1.day.from_now.to_s }
  let(:encrypted_cookie_value) { encrypt_string(time_to_string) }
  let(:non_reading_room_ip) { '198.51.100.255' }
  let(:reading_room_ip) { '192.0.0.255' }

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
          'User-Agent' => 'http.rb/4.4.1'
        }
      )
      .to_return(status: 200, body: "I am returning an image, but for now I'm words", headers: {})
  end

  describe "GET image" do
    context "with a Public object" do
      let(:attributes) do
        { "id" => work_id,
          "sha1_tesim" => ["urn:sha1:#{image_sha}"],
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
          "sha1_tesim" => ["urn:sha1:#{image_sha}"],
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
          "sha1_tesim" => ["urn:sha1:#{image_sha}"],
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

      context "a user who has a spoofed cookie" do
        before do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{spoofed_cookie_value}" })
        end

        it "does not return an image" do
          expect(response.status).to eq 403
          expect(response.body).to be_empty
        end
      end

      context "a user who has a badly spoofed cookie" do
        before do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{badly_spoofed_cookie_value}" })
        end

        it "does not return an image" do
          expect(response.status).to eq 403
          expect(response.body).to be_empty
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

    context "with a private object" do
      let(:attributes) do
        { "id" => work_id,
          "sha1_tesim" => ["urn:sha1:#{image_sha}"],
          "visibility_ssi" => "restricted" }
      end
      let(:region) { "100,100,800,800" }
      let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/#{region}/#{size}/0/default.jpg" }
      let(:admin_user) { FactoryBot.create(:admin) }
      context "as a Curate admin" do
        it "does not alter the region" do
          login_as admin_user
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
          expect(assigns(:iiif_url)).to eq expected_iiif_url
        end
      end
    end
    context "with an Emory High Download object" do
      let(:attributes) do
        { "id" => work_id,
          "sha1_tesim" => ["urn:sha1:#{image_sha}"],
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
      context "a request for a specific region" do
        let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/100,100,800,800/#{size}/0/default.jpg" }
        it "does not alter the region" do
          get("/iiif/2/#{image_sha}/100,100,800,800/#{size}/#{rotation}/#{quality}.#{format}", headers: { "HTTP_COOKIE" => "#{cookie_name}=#{encrypted_cookie_value}" })
          expect(assigns(:iiif_url)).to eq expected_iiif_url
        end
      end
    end

    context "with a Rose High View object" do
      let(:attributes) do
        { "id" => work_id,
          "sha1_tesim" => ["urn:sha1:#{image_sha}"],
          "visibility_ssi" => "rose_high" }
      end
      let(:expected_iiif_url) { "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/#{image_sha}/100,100,800,800/#{size}/0/default.jpg" }
      context "within the Rose Reading Room" do
        it "returns the image for a work with 'Rose High View' visibility with Remote Address" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "REMOTE_ADDR": reading_room_ip })

          expect(request.headers["REMOTE_ADDR"]).to eq reading_room_ip
          expect(response.status).to eq 200
        end

        it "returns the image for a work with 'Rose High View' visibility with X-Forwarded-For" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "X-Forwarded-For": reading_room_ip })

          expect(request.headers["X-Forwarded-For"]).to eq reading_room_ip
          expect(response.status).to eq 200
        end

        it "does not change the region" do
          get("/iiif/2/#{image_sha}/100,100,800,800/#{size}/#{rotation}/#{quality}.#{format}", headers: { "REMOTE_ADDR": reading_room_ip })
          expect(assigns(:iiif_url)).to eq expected_iiif_url
        end
      end

      context "not in the Rose Reading Room" do
        it "does not return the image for a work with 'Rose High View' visibility with Remote Address" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "REMOTE_ADDR": non_reading_room_ip })
          expect(response.status).to eq 403
          expect(response.body).to be_empty
        end

        it "does not return the image for a work with 'Rose High View' visibility with X-Forwarded-For" do
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "X-Forwarded-For": non_reading_room_ip })
          expect(response.status).to eq 403
          expect(response.body).to be_empty
        end
      end

      context "a Curate admin not in the Rose reading room" do
        let(:admin_user) { FactoryBot.create(:admin) }

        it "does return the image for a work with 'Rose High View' visibility with Remote Address" do
          login_as admin_user
          get("/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}", headers: { "REMOTE_ADDR": non_reading_room_ip })
          expect(response.status).to eq 200
        end
      end
    end
  end
  def encrypt_string(str)
    cipher_salt1 = ENV["IIIF_COOKIE_SALT_1"] || 'some-random-salt-'
    cipher_salt2 = ENV["IIIF_COOKIE_SALT_2"] || 'another-random-salt-'
    cipher = OpenSSL::Cipher.new('AES-128-ECB').encrypt
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(cipher_salt1, cipher_salt2, 20_000, cipher.key_len)
    encrypted = cipher.update(str) + cipher.final
    encrypted.unpack('H*')[0].upcase
  end
end
