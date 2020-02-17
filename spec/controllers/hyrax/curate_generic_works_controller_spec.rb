# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::CurateGenericWorksController do
  let(:work) { FactoryBot.create(:public_generic_work, id: '888889') }
  describe "GET #manifest" do
    before { ENV['IIIF_MANIFEST_CACHE'] = "./tmp" }

    it "returns http success" do
      get :manifest, params: { id: work.id, format: 'json' }
      expect(response).to have_http_status(:success)
    end
  end
end
