# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers
# http://127.0.0.1:8182/iiif/2/river_with_jam.jpg/full/full/0/default.jpg
# https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/ab4c45f5ce3e65dc9fe039f8e3e35b29ce883453/full/600,/0/default.jpg
RSpec.describe 'proxy iiif traffic', type: :system do
  let(:identifier) { "508hdr7srt-cor" }
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

  let(:user) { FactoryBot.build(:user) }
  let(:identifier) { "508hdr7srt-cor" }
  let(:attributes) do
    { "id" => "85370rxwg2-cor",
      "digest_ssim" => ["urn:sha1:#{image_sha}"],
      "visibility_ssi" => "authenticated" }
  end

  before do
    solr = Blacklight.default_index.connection
    solr.add([attributes])
    solr.commit
    ENV['PROXIED_IIIF_SERVER_URL'] = 'http://127.0.0.1:8182/iiif/2'
    stub_request(:any, /127.0.0.1:8182/).to_return(
      body:    "SUCCESS",
      status:  200,
      headers: { 'Content-Length' => 3 }
    )
  end

  context "as an authenticated user" do
    it 'returns a jpeg', clean: true do
      login_as user

      visit "/iiif/2/#{image_sha}/full/full/0/default.jpg"
      expect(page.status_code).to eq 200
    end
  end

  context "as an unauthenticated user" do
    it 'gives a 403 unauthorized message', clean: true do
      visit "/iiif/2/#{image_sha}/full/full/0/default.jpg"
      expect(page.status_code).to eq 403
    end
  end
end
