# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'iiif access controls', type: :system do
  let(:work_id) { "436tx95xcc-cor" }
  let(:image_sha) { "79276774f3dbfbd977d39065eec14aa185b5213d" }
  let(:region) { "full" }
  let(:size) { "full" }
  let(:rotation) { 0 }
  let(:quality) { "default" }
  let(:format) { "jpg" }
  let(:encrypted_cookie_value) { "43BB3AA86080214273B978723D70DE6894DB9DEAC93FB27C79799EAD405B3FE8" }

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
      .to_return(status: 200, body: "", headers: {})
      solr = Blacklight.default_index.connection
      solr.add([attributes])
      solr.commit
  end

  context "Public objects" do
    let(:attributes) do
      { "id" => work_id,
        "digest_ssim" => ["urn:sha1:#{image_sha}"],
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
        "digest_ssim" => ["urn:sha1:#{image_sha}"],
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
        "digest_ssim" => ["urn:sha1:#{image_sha}"],
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
      end
    end
  end

  context "for Emory High Download objects" do
    let(:attributes) do
      { "id" => work_id,
        "digest_ssim" => ["urn:sha1:#{image_sha}"],
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
      end
    end
  end

  context "Rose High View objects" do
    let(:attributes) do
      { "id" => work_id,
        "digest_ssim" => ["urn:sha1:#{image_sha}"],
        "visibility_ssi" => "rose_high" }
    end

    it 'visits a iiif_url', clean: true do
      visit iiif_url
      expect(page).to have_http_status(403)
    end
  end

  context "Private objects" do

  end
end
