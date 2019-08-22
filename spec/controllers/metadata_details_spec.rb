# frozen_string_literal: true
# [Hyrax-overwrite] Adds tests for additional files
require 'rails_helper'

RSpec.describe MetadataDetailsController, type: :controller do
  describe 'GET show'
  it 'has 200 code for show' do
    get :show
    expect(response.status).to eq(200)
  end

  it 'has details' do
    get :show
    details = assigns(:details)
    expect(details['title'][:predicate]).to eq('http://purl.org/dc/terms/title')
  end

  it 'has a downloadable csv' do
    get :csv
    expect(response.content_type).to eq('text/csv')
  end
end
