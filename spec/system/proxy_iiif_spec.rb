# frozen_string_literal: true
require 'rails_helper'
include Warden::Test::Helpers

RSpec.describe 'proxy iiif traffic', type: :system do
  let(:iiif_url) { '/iiif/2/436tx95x8c-cor/full/600,/0/default.jpg' }

  it 'has all the labels', clean: true do
    visit iiif_url
    puts iiif_url
  end
end
