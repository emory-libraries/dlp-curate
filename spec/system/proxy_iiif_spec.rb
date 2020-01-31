# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers
# http://127.0.0.1:8182/iiif/2/river_with_jam.jpg/full/full/0/default.jpg
# https://iiif-cor-arch.library.emory.edu/cantaloupe/iiif/2/ab4c45f5ce3e65dc9fe039f8e3e35b29ce883453/full/600,/0/default.jpg
RSpec.describe 'proxy iiif traffic', type: :system do
  let(:iiif_url) { '/iiif/2/river_with_jam.jpg/full/full/0/default.jpg' }

  it 'has all the labels', clean: true do
    visit iiif_url
    expect(page.response_headers["Content-Type"]).to eq "image/jpeg"
  end
end
