# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Admin::AdminSetsController, type: :controller, clean: true do
  routes { Hyrax::Engine.routes }

  let(:admin) { FactoryBot.create(:admin) }
  let!(:admin_set) do
    FactoryBot.create(:admin_set, title: ['Default Admin Set'], with_permission_template: true)
  end

  before do
    sign_in admin
    Hyrax::CollectionType.find_or_create_admin_set_type
    Hyrax::SolrService.commit
  end

  describe '#show' do
    it 'renders the admin set' do
      get :show, params: { id: admin_set.id, locale: 'en' }

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
      expect(assigns(:presenter).id).to eq(admin_set.id)
    end

    context 'when persistence lookup fails but Solr has the document' do
      before do
        allow(Hyrax.query_service).to receive(:find_by)
          .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it 'renders the admin set from Solr instead of 404ing' do
        get :show, params: { id: admin_set.id, locale: 'en' }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(assigns(:presenter).id).to eq(admin_set.id)
      end
    end
  end
end
