# frozen_string_literal: true
require 'rails_helper'

# [Hyrax-overwrite-hyrax-v5.2.0]
RSpec.describe Hyrax::Dashboard::CollectionsController, :clean do
  routes { Hyrax::Engine.routes }
  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:collection) { FactoryBot.create(:public_collection_lw, id: '888889', user: user, with_permission_template: true) }

  describe "#delete" do
    context "when logged in as an admin" do
      before { sign_in admin }
      it "destroys the collection" do
        delete :destroy, params: { id: collection }
        expect(response).to have_http_status(:found)
        expect(Collection.count).to eq 0
      end
    end

    context "when logged in as a non-admin user" do
      before { sign_in user }
      it "does not destroy the collection" do
        delete :destroy, params: { id: collection }
        expect(response).not_to be_successful
        expect(Collection.count).to eq 1
      end
    end
  end
end
