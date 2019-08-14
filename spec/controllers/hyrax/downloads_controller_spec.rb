# frozen_string_literal: true
# [Hyrax-overwrite] Adds tests for additional files
require 'rails_helper'

RSpec.describe Hyrax::DownloadsController do
  routes { Hyrax::Engine.routes }

  describe '#show' do
    let(:user) { FactoryBot.create(:user) }
    let(:file_set) { FactoryBot.create(:file_set, user: user, title: ['Some title']) }
    let(:file) { File.open(fixture_path + '/image.png') }
    let(:file1) { File.open(fixture_path + '/balloon.jpeg') }
    let(:file2) { File.open(fixture_path + '/jp2_fits.xml') }
    let(:file3) { File.open(fixture_path + '/cat.jpeg') }

    before do
      Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
      Hydra::Works::AddFileToFileSet.call(file_set, file1, :service_file)
      Hydra::Works::AddFileToFileSet.call(file_set, file2, :extracted)
      Hydra::Works::AddFileToFileSet.call(file_set, file3, :intermediate_file)
    end

    it 'raises an error if the object does not exist' do
      expect do
        get :show, params: { id: '8675309' }
      end.to raise_error Blacklight::Exceptions::InvalidSolrID
    end

    context "when user doesn't have access" do
      let(:another_user) { FactoryBot.create(:user) }

      before { sign_in another_user }

      it 'returns :unauthorized status with image content' do
        get :show, params: { id: file_set.to_param }
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq 'image/png'
      end
    end

    context "when user isn't logged in" do
      context "and the unauthorized image exists" do
        before do
          allow(File).to receive(:exist?).and_return(true)
        end

        it 'returns :unauthorized status with image content' do
          get :show, params: { id: file_set.to_param }
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to eq 'image/png'
        end
      end

      it 'authorizes the resource using only the id' do
        expect(controller).to receive(:authorize!).with(:download, file_set.id)
        get :show, params: { id: file_set.to_param }
      end
    end

    context "when the user has access" do
      before { sign_in user }

      it 'sends the preservation master file' do
        get :show, params: { id: file_set }
        expect(response.body).to eq file_set.preservation_master_file.content
      end

      it 'sends the service file' do
        get :show, params: { id: file_set, use: 'service_file' }
        expect(response.body).to eq file_set.service_file.content
      end

      it 'sends the extracted text' do
        get :show, params: { id: file_set, use: 'extracted_text' }
        expect(response.body).to eq file_set.extracted.content
      end

      it 'sends the intermediate file' do
        get :show, params: { id: file_set, use: 'intermediate_file' }
        expect(response.body).to eq file_set.intermediate_file.content
      end

      context "with an alternative file" do
        context "that is persisted" do
          let(:file) { File.open(fixture_path + '/world.png', 'rb') }
          let(:content) { file.read }

          before do
            allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).and_return(fixture_path + '/world.png')
          end

          it 'sends requested file content' do
            get :show, params: { id: file_set, file: 'thumbnail' }
            expect(response).to be_success
            expect(response.body).to eq content
            expect(response.headers['Content-Length']).to eq "0"
            expect(response.headers['Accept-Ranges']).to eq "bytes"
          end

          it 'retrieves the thumbnail without contacting Fedora' do
            expect(ActiveFedora::Base).not_to receive(:find).with(file_set.id)
            get :show, params: { id: file_set, file: 'thumbnail' }
          end

          context "stream" do
            it "head request" do
              request.env["HTTP_RANGE"] = 'bytes=0-15'
              head :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers['Content-Length']).to eq '0'
              expect(response.headers['Accept-Ranges']).to eq 'bytes'
              expect(response.headers['Content-Type']).to start_with 'image/png'
            end

            it "sends the whole thing" do
              request.env["HTTP_RANGE"] = 'bytes=0-4217'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 0-4217/0'
              expect(response.headers["Content-Length"]).to eq '4218'
              expect(response.headers['Accept-Ranges']).to eq 'bytes'
              expect(response.headers['Content-Type']).to start_with "image/png"
              expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"world.png\""
              expect(response.body).to eq content
              expect(response.status).to eq 206
            end

            it "sends the whole thing when the range is open ended" do
              request.env["HTTP_RANGE"] = 'bytes=0-'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.body).to eq content
            end

            it "gets a range not starting at the beginning" do
              request.env["HTTP_RANGE"] = 'bytes=4200-4217'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 4200-4217/0'
              expect(response.headers["Content-Length"]).to eq '18'
            end

            it "gets a range not ending at the end" do
              request.env["HTTP_RANGE"] = 'bytes=4-11'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 4-11/0'
              expect(response.headers["Content-Length"]).to eq '8'
            end
          end
        end

        context "that isn't persisted" do
          it "raises an error if the requested file does not exist" do
            expect do
              get :show, params: { id: file_set, file: 'thumbnail' }
            end.to raise_error ActiveFedora::ObjectNotFoundError
          end
        end
      end

      it "raises an error if the requested association does not exist" do
        expect do
          get :show, params: { id: file_set, file: 'non-existant' }
        end.to raise_error ActiveFedora::ObjectNotFoundError
      end
    end
  end

  describe "derivative_download_options" do
    before do
      allow(controller).to receive(:default_file).and_return 'world.png'
    end
    subject { controller.send(:derivative_download_options) }

    it { is_expected.to eq(disposition: 'inline', type: 'image/png') }
  end
end
