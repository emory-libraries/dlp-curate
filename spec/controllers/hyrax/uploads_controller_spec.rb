# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0] spec/controllers/hyrax/uploads_controller_spec.rb
require 'rails_helper'

RSpec.describe Hyrax::UploadsController do
  routes { Hyrax::Engine.routes }
  let(:user) { FactoryBot.create(:user) }
  let(:filename1) { 'world.png' }
  let(:filename2) { 'sun.png' }
  let(:file_path1) { Rails.root.join('spec', 'fixtures', filename1) }
  let(:file_path2) { Rails.root.join('spec', 'fixtures', filename2) }
  let(:file1) { Rack::Test::UploadedFile.new(file_path1, 'image/png') }
  let(:file2) { Rack::Test::UploadedFile.new(file_path2, 'image/png') }

  describe "#create" do
    context "when signed in" do
      before { sign_in user }

      it "is successful with pmf" do
        post :create, params: { preservation_master_file: file1, format: 'json' }
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
        post :create, params: { files: [file1], format: 'json' }
        expect(response.status).to eq 401
      end
    end
  end
end
