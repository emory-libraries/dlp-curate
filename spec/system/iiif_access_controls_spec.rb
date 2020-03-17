# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'iiif access controls', type: :system do
  let(:public_work_id) { "658pc866ww-cor" }
  let(:work_id) { "436tx95xcc-cor" }
  let(:public_image_sha) { "465c0075481fe4badc58c76fba42161454a18d1f" }
  let(:image_sha) { "79276774f3dbfbd977d39065eec14aa185b5213d" }
  let(:region) { "full" }
  let(:size) { "full" }
  let(:rotation) { 0 }
  let(:quality) { "default" }
  let(:format) { "jpg" }

  let(:iiif_url) { "/iiif/2/#{public_image_sha}/#{region}/#{size}/#{rotation}/#{quality}.#{format}" }

  before do
    ENV['PROXIED_IIIF_SERVER_URL'] = 'https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2'
    stub_request(:get, "https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/465c0075481fe4badc58c76fba42161454a18d1f/full/full/0/default.jpg").
      with(
        headers: {
       'Connection'=>'close',
       'Host'=>'iiif-cor-arch.library.emory.edu',
       'User-Agent'=>'http.rb/4.3.0'
        }).
      to_return(status: 200, body: "", headers: {})
  end

  context "As a user who has authenticated to Lux" do
    before do
      create_cookie("bearer_token", "another string")
    end

    it 'visits a iiif_url', clean: true do
      visit iiif_url
    end
  end

  context "As a user who has *not* authenticated to Lux" do
    it 'visits a iiif_url', clean: true do
      visit iiif_url
    end
  end
end
