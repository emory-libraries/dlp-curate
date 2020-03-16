
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
      # let(:key) { Rails.application.secrets.shared_cookie_key }
      let(:key) { "y8W9gASeJKAO906o2wwUVRDqZQgERrsH" }
      let(:crypt) { ActiveSupport::MessageEncryptor.new(key) }
      let(:user) { User.from_omniauth(auth_hash) }
      let(:cookie_name) { "bearer_token" }
      let(:encrypted_cookie_value) { "43BB3AA86080214273B978723D70DE6894DB9DEAC93FB27C79799EAD405B3FE8" }
      let(:cookie) { Rack::Test::Cookie.new("#{cookie_name}=#{encrypted_cookie_value}") }

      before do
        solr = Blacklight.default_index.connection
        solr.add([attributes])
        solr.commit
        cookies << cookie
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
        expect(cookies.to_hash["bearer_token"]).to eq encrypted_cookie_value
        expect(decrypt_string(cookies.to_hash["bearer_token"])).to eq "This is a test token value"
      end
    end
  end

  def decrypt_string(encrypted_str)
    cipher_salt1 = 'some-random-salt-'
    cipher_salt2 = 'another-random-salt-'
    cipher = OpenSSL::Cipher.new('AES-128-ECB').decrypt
    cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(cipher_salt1, cipher_salt2, 20_000, cipher.key_len)
    decrypted = [encrypted_str].pack('H*').unpack('C*').pack('c*')
    cipher.update(decrypted) + cipher.final
  end
end
