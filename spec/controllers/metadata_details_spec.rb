# frozen_string_literal: true
# [Hyrax-overwrite] Adds tests for additional files
require 'rails_helper'

RSpec.describe MetadataDetailsController, type: :controller do
  describe 'GET show' do
    it 'has 200 code for show' do
      get :show
      expect(response.status).to eq(200)
    end

    describe 'details' do
      it 'includes predicate' do
        get :show
        details = assigns(:details)
        expect(details['title'][:predicate]).to eq('http://purl.org/dc/terms/title')
      end

      it 'includes csv_header' do
        get :show
        details = assigns(:details)
        expect(details['title'][:csv_header]).to eq('title')
      end
    end
  end

  describe 'GET csv' do
    it 'is downloadable' do
      get :csv
      expect(response.content_type).to eq('text/csv')
    end

    it 'includes csv_header' do
      get :csv
      first_row = response.body.lines.first
      expect(first_row).to include('csv_header')
    end
  end
end
