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

  it 'includes expected headers' do
    get :csv
    first_row = response.body.lines.first
    expect(first_row).to include('csv_header')
    expect(first_row).to include('required_on_form')
  end

  it 'includes a date in the filename' do
    todays_date = Date.new(1985, 7, 3)
    allow(Date).to receive(:current) { todays_date }

    get :csv
    filename = response.headers['Content-Disposition']
    expect(filename).to include todays_date.to_s
  end
end
