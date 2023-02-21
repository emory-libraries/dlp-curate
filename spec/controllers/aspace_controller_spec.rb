# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AspaceController, type: :controller do
  let(:service) { instance_double(Aspace::ApiService) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:repository_data) do
    {
      name:                'Test Library',
      administrative_unit: 'Test Library',
      holding_repository:  'Test Library',
      institution:         'Emory University',
      contact_information: ''
    }
  end
  let(:resource_data) do
    {
      title:                'Test Resource',
      description:          'This is a description',
      creator:              ['Test Creator'],
      system_of_record_id:  '/repositories/1/resources/1',
      call_number:          'call number',
      primary_language:     'English',
      subject_topics:       [],
      subject_names:        [],
      subject_geo:          [],
      subject_time_periods: []
    }
  end

  before do
    allow(Aspace::ApiService).to receive(:new).and_return(service)
  end

  describe '#authorize_resource' do
    before do
      allow(service).to receive(:authenticate!).and_return(service)
      allow(service).to receive(:fetch_repositories).and_return([repository_data])
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
          expect(response.body).to eq("[{\"name\":\"Test Library\",\"administrative_unit\":\"\",\"holding_repository\":\"\",\"institution\":\"Emory University\",\"contact_information\":\"\"}]")
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

  describe '#authenticate' do
    context 'when an API authentication error is raised' do
      before do
        allow(service).to receive(:authenticate!).and_raise(Aspace::ApiService::AuthenticationError, 'Unable to authenticate to ArchivesSpace')
        sign_in(admin)
      end

      it 'returns error response' do
        get :repositories, format: :json
        expect(response.body).to eq("{\"error\":\"ArchivesSpace API error: Unable to authenticate to ArchivesSpace\"}")
      end
    end
  end

  describe '#verify_json_request' do
    context 'when format requested is not json' do
      before do
        sign_in(admin)
      end

      it 'returns bad request response' do
        get :repositories, format: :html
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq("")
      end
    end
  end

  describe '#repositories' do
    before do
      allow(service).to receive(:authenticate!).and_return(service)
      allow(service).to receive(:fetch_repositories).and_return([repository_data])
      sign_in(admin)
    end

    it 'fetches repositories from ArchivesSpace' do
      get :repositories, format: :json
      expect(response.body).to eq("[{\"name\":\"Test Library\",\"administrative_unit\":\"\",\"holding_repository\":\"\",\"institution\":\"Emory University\",\"contact_information\":\"\"}]")
    end

    context 'when an API client error is raised' do
      before do
        allow(service).to receive(:fetch_repositories).and_raise(Aspace::ApiService::ClientError, 'Test client error')
      end

      it 'returns error response' do
        get :repositories, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("{\"error\":\"ArchivesSpace API error: Test client error\"}")
      end
    end

    context 'when an API server error is raised' do
      before do
        allow(service).to receive(:fetch_repositories).and_raise(Aspace::ApiService::ServerError, 'Test server error')
      end

      it 'returns error response' do
        get :repositories, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("{\"error\":\"ArchivesSpace API error: Test server error\"}")
      end
    end
  end

  describe '#find_by_id' do
    before do
      allow(service).to receive(:authenticate!).and_return(service)
      allow(service).to receive(:fetch_repository_by_id).and_return(repository_data)
      allow(service).to receive(:fetch_resource_by_call_number).and_return(resource_data)
      sign_in(admin)
    end

    it 'fetches resource from ArchivesSpace' do
      get :find_by_id, params: { repository_id: 1, resource_id: 1 }, format: :json
      # rubocop:disable Layout/LineLength
      expect(response.body).to eq("{\"repository\":{\"name\":\"Test Library\",\"administrative_unit\":\"Test Library\",\"holding_repository\":\"Test Library\",\"institution\":\"Emory University\",\"contact_information\":\"\"},\"resource\":{\"title\":\"Test Resource\",\"description\":\"This is a description\",\"creator\":[\"Test Creator\"],\"system_of_record_id\":\"/repositories/1/resources/1\",\"call_number\":\"call number\",\"primary_language\":\"\",\"subject_topics\":[],\"subject_names\":[],\"subject_geo\":[],\"subject_time_periods\":[],\"administrative_unit\":\"\",\"holding_repository\":\"\"}}")
      # rubocop:enable Layout/LineLength
    end

    context 'when repository_id param is missing' do
      it 'returns error response' do
        get :find_by_id, params: { resource_id: 1 }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("{\"error\":\"Invalid request error: repository_id must be specified\"}")
      end
    end

    context 'when resource_id param is missing' do
      it 'returns error response' do
        get :find_by_id, params: { repository_id: 1 }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("{\"error\":\"Invalid request error: resource_id must be specified\"}")
      end
    end

    context 'when an API client error is raised' do
      before do
        allow(service).to receive(:fetch_resource_by_call_number).and_raise(Aspace::ApiService::ClientError, 'Test client error')
      end

      it 'returns error response' do
        get :find_by_id, params: { repository_id: 1, resource_id: 1 }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("{\"error\":\"ArchivesSpace API error: Test client error\"}")
      end
    end

    context 'when an API server error is raised' do
      before do
        allow(service).to receive(:fetch_resource_by_call_number).and_raise(Aspace::ApiService::ServerError, 'Test server error')
      end

      it 'returns error response' do
        get :find_by_id, params: { repository_id: 1, resource_id: 1 }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("{\"error\":\"ArchivesSpace API error: Test server error\"}")
      end
    end
  end
end
