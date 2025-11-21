# frozen_string_literal: true
require 'rails_helper'

# Deprecation Warning: As of Curate v3, Zizia will be removed. This is an artifact
#   of the Zizia install that will likely be removed.
RSpec.describe CsvImportDetailsController, clean: true, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let!(:csv_import) { FactoryBot.create(:csv_import, id: '1', user: FactoryBot.create(:user, id: '1')) }
  let!(:csv_import_detail) { FactoryBot.create(:csv_import_detail, csv_import_id: csv_import.id) }

  describe '#index' do
    context 'when a non-admin user is signed in' do
      before do
        sign_in user
      end

      it 'redirects due to unauthorized access' do
        get :index
        expect(response)
          .to fail_redirect_and_flash(root_path,
                                      'You are not authorized to access this page.')
      end
    end

    context 'when an admin user is signed in' do
      before do
        sign_in admin
      end

      it 'is successful' do
        get :index
        expect(response).to be_successful
      end
    end

    context 'when no user is signed in' do
      it 'redirects due to unauthorized access' do
        get :index
        expect(response)
          .to fail_redirect_and_flash(main_app.new_user_session_path,
                                      'You need to sign in or sign up before continuing.')
      end
    end
  end

  describe '#show' do
    context 'when a non-admin user is signed in' do
      before do
        sign_in user
      end

      it 'is unauthorized' do
        get :show, params: { id: csv_import_detail.id }
        expect(response.code).to eq '401'
        expect(response).to render_template 'unauthorized'
      end
    end

    context 'when an admin user is signed in' do
      before do
        sign_in admin
      end

      it 'is successful' do
        get :show, params: { id: csv_import_detail.id }
        expect(response).to be_successful
      end
    end

    context 'when no user is signed in' do
      it 'redirects due to unauthorized access' do
        get :show, params: { id: csv_import_detail.id }
        expect(response)
          .to fail_redirect_and_flash(main_app.new_user_session_path,
                                      'You need to sign in or sign up before continuing.')
      end
    end
  end
end
