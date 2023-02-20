# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AspaceController, type: :controller do
  let(:service) { instance_double(Aspace::ApiService) }

  before do
    allow(Aspace::ApiService).to receive(:new).and_return(service)
    allow(service).to receive(:authenticate!).and_return(service)
  end

  describe '#authorize_resource' do
    before do
      allow(service).to receive(:fetch_repositories).and_return([])
    end

    context 'when a user is logged in' do
      before do
        sign_in(user)
      end

      context 'and is an admin' do
        let(:user) { FactoryBot.create(:admin) }

        it 'authorizes access to data' do
          get :repositories, format: :json
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq("[]")
        end
      end

      context 'and is not an admin' do
        let(:user) { FactoryBot.create(:user) }

        it 'denies access to data' do
          sign_in(user)
          get :repositories, format: :json
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to eq("{\"code\":403,\"message\":\"Not Authorized\",\"description\":\"You are not authorized to access this content.\"}")
        end
      end
    end

    context 'when no user is logged in' do
      it 'denies access to data' do
        get :repositories, format: :json
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to eq("{\"error\":\"You need to sign in or sign up before continuing.\"}")
      end
    end
  end
end
