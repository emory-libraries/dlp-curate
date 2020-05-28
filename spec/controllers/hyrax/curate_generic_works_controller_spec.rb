# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::CurateGenericWorksController, :clean do
  let(:work) { FactoryBot.create(:public_generic_work, id: '888889', user: user) }
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }

  describe "GET #manifest" do
    before { ENV['IIIF_MANIFEST_CACHE'] = "./tmp" }

    it "returns http success" do
      sign_in user
      get :manifest, params: { id: work.id, format: 'json' }
      expect(response).to have_http_status(:success)
    end
  end

  describe "#delete" do
    context "when logged in as an admin" do
      it "redirects to My Works" do
        sign_in admin
        delete :destroy, params: { id: work }
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
        expect(flash[:notice]).to eq "Deleted Test title"
      end
    end

    context "when logged in as a non-admin user" do
      it "redirects to the edit view" do
        sign_in user
        delete :destroy, params: { id: work }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:edit)
        expect(flash[:notice]).to eq "Test title could not be deleted"
      end
    end
  end
end
