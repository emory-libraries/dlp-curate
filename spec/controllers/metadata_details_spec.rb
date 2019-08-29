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
    get :profile
    expect(response.content_type).to eq('text/csv')
  end

  it 'includes expected headers' do
    get :profile
    first_row = response.body.lines.first
    expect(first_row).to include('csv_header')
    expect(first_row).to include('required_on_form')
  end

  it 'includes usage' do
    get :profile
    profile_table = CSV.parse(response.body, headers: :first_row)
    title_definition = profile_table.find { |r| r.field('attribute') == 'title' }
    expect(title_definition.field('usage')).to include 'name of the resource being described' # match text extracted from ./config/emory/usage.yml
  end

  it 'includes a date in the filename' do
    todays_date = "Wed, 03 Jul 1985".to_date
    allow(Date).to receive(:current) { todays_date }

    get :profile
    filename = response.headers['Content-Disposition']
    expect(filename).to include "1985-07-03"
  end
end
