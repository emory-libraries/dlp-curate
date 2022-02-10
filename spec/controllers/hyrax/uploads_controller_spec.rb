# frozen_string_literal: true
# [Hyrax-overwrite-v3.1.0]
require 'rails_helper'

RSpec.describe Hyrax::UploadsController do
  routes { Hyrax::Engine.routes }

  let(:user) { FactoryBot.create(:user) }

  describe "#create" do
    let(:file)  { fixture_file_upload('/world.png', 'image/png') }
    let(:file2) { fixture_file_upload('/sun.png', 'image/png') }

    context "when signed in" do
      before do
        sign_in user
      end
      it "is successful with pmf" do
        post :create, params: { preservation_master_file: file, format: 'json' }
        expect(response).to be_successful
        expect(assigns(:upload)).to be_kind_of Hyrax::UploadedFile
        expect(assigns(:upload)).to be_persisted
        expect(assigns(:upload).user).to eq user
        expect(assigns(:upload).preservation_master_file.file.original_filename).to eq 'world.png'
      end
      it "is successful with collection_banner" do
        post :create, params: { collection_banner: file2, format: 'json' }
        expect(assigns(:upload)).to be_kind_of Hyrax::UploadedFile
        expect(assigns(:upload)).to be_persisted
        expect(assigns(:upload).user).to eq user
        expect(assigns(:upload).collection_banner.file.original_filename).to eq 'sun.png'
      end
    end

    context "when not signed in" do
      it "is unauthorized" do
        post :create, params: { files: [file], format: 'json' }
        expect(response.status).to eq 401
      end
    end
  end
end
