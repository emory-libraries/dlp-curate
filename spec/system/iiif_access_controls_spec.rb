# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'iiif access controls', type: :system, iiif: true do
  let(:work_id) { "436tx95xcc-cor" }
  let(:image_sha) { "79276774f3dbfbd977d39065eec14aa185b5213d" }
  let(:region) { "full" }
  let(:size) { "full" }
  let(:rotation) { 0 }
  let(:quality) { "default" }
  let(:format) { "jpg" }
  let(:time_to_string) { 1.day.from_now.to_s }
  let(:encrypted_cookie_value) { encrypt_string(time_to_string) }

  let(:iiif_url) { "/iiif/2/#{image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}" }

  before do
    ENV['PROXIED_IIIF_SERVER_URL'] = 'https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2'
    stub_request(:any, /iiif-cor-arch.library.emory.edu/)
      .with(
        headers: {
          'Connection' => 'close',
          'Host' => 'iiif-cor-arch.library.emory.edu',
          'User-Agent' => 'http.rb/4.3.0'
        }
      )
      .to_return(status: 200, body: "I am returning an image, but for now I'm words", headers: {})
    solr = Blacklight.default_index.connection
    solr.add([attributes])
    solr.commit
  end

  context "Public objects" do
    let(:attributes) do
      { "id" => work_id,
        "sha1_tesim" => ["urn:sha1:#{image_sha}"],
        "visibility_ssi" => "open" }
    end

    it 'visits a iiif_url', clean: true do
      visit iiif_url
      expect(page).to have_http_status(200)
    end
  end

  context "Public low view object" do
    let(:attributes) do
      { "id" => work_id,
        "sha1_tesim" => ["urn:sha1:#{image_sha}"],
        "visibility_ssi" => "low_res" }
    end

    it 'visits a iiif_url', clean: true do
      visit iiif_url
      expect(page).to have_http_status(200)
    end
  end

  context "Emory Low Download objects" do
    let(:attributes) do
      { "id" => work_id,
        "sha1_tesim" => ["urn:sha1:#{image_sha}"],
        "visibility_ssi" => "emory_low" }
    end

    context "As a user who has authenticated to Lux" do
      before do
        create_cookie("bearer_token", encrypted_cookie_value)
      end

      it 'visits a iiif_url', clean: true do
        visit iiif_url
        expect(page).to have_http_status(200)
      end
    end

    context "As a user who has *not* authenticated to Lux" do
      it 'visits a iiif_url', clean: true do
        visit iiif_url
        expect(page).to have_http_status(403)
        expect(page.body).to be_empty
      end
    end

    context "As a Curate user" do
      let(:user) { FactoryBot.create(:user) }

      it 'visits a iiif_url', clean: true do
        login_as user
        visit iiif_url
        expect(page).to have_http_status(200)
      end
    end
  end

  context "for Emory High Download objects" do
    let(:attributes) do
      { "id" => work_id,
        "sha1_tesim" => ["urn:sha1:#{image_sha}"],
        "visibility_ssi" => "authenticated" }
    end

    context "As a user who has authenticated to Lux" do
      before do
        create_cookie("bearer_token", encrypted_cookie_value)
      end

      it 'visits a iiif_url', clean: true do
        visit iiif_url
        expect(page).to have_http_status(200)
      end
    end

    context "As a user who has *not* authenticated to Lux" do
      it 'visits a iiif_url', clean: true do
        visit iiif_url
        expect(page).to have_http_status(403)
        expect(page.body).to be_empty
      end
    end
  end
  # TODO: This is a holding pattern until we can really implement Rose Reading Room IPs
  context "Rose High View objects" do
    let(:attributes) do
      { "id" => work_id,
        "sha1_tesim" => ["urn:sha1:#{image_sha}"],
        "visibility_ssi" => "rose_high" }
    end

    it 'visits a iiif_url', clean: true do
      visit iiif_url
      expect(page).to have_http_status(403)
      expect(page.body).to be_empty
    end
  end

  context "Private objects" do
    let(:attributes) do
      { "id" => work_id,
        "sha1_tesim" => ["urn:sha1:#{image_sha}"],
        "visibility_ssi" => "restricted" }
    end

    context "for a completely unauthenticated user" do
      it 'visits a iiif_url', clean: true do
        visit iiif_url
        expect(page).to have_http_status(403)
        expect(page.body).to be_empty
      end
    end

    context "for a regular Emory user (authenticated via Lux)" do
      before do
        create_cookie("bearer_token", encrypted_cookie_value)
      end

      it 'visits a iiif_url', clean: true do
        visit iiif_url
        expect(page).to have_http_status(403)
        expect(page.body).to be_empty
      end
    end

    context "for a Curate admin user" do
      let(:admin_user) { FactoryBot.create(:admin) }

      it 'visits a iiif_url', clean: true do
        login_as admin_user
        visit iiif_url
        expect(page).to have_http_status(200)
      end
    end

    context "for a Curate user who is not an admin" do
      let(:user) { FactoryBot.create(:user) }

      it 'visits a iiif_url', clean: true do
        login_as user
        visit iiif_url
        expect(page).to have_http_status(200)
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
