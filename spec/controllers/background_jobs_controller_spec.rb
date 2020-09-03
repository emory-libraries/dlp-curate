# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackgroundJobsController, type: :controller, clean: true do
  include ActionDispatch::TestProcess

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:csv_file) { fixture_file_upload((fixture_path + '/reindex_files.csv'), 'text/csv') }
  let(:csv_file2) { fixture_file_upload((fixture_path + '/preservation_workflows.csv'), 'text/csv') }

  context "when signed in" do
    before do
      sign_in admin
    end

    describe "#new" do
      it 'has 200 code for new' do
        get :new
        expect(response.status).to eq(200)
      end
    end

    describe "#create" do
      it "successfully starts a file_set cleanup background job" do
        post :create, params: { jobs: 'cleanup', format: 'json' }
        response.should redirect_to(new_background_job_path)
      end
      it "successfully starts a preservation workflow background job" do
        post :create, params: { jobs: 'preservation', preservation_csv: csv_file, format: 'json' }
        expect(PreservationWorkflowImporterJob).to have_been_enqueued
        response.should redirect_to(new_background_job_path)
      end
      it "successfully starts a reindex background job" do
        post :create, params: { jobs: 'reindex', reindex_csv: csv_file2, format: 'json' }
        expect(ReindexObjectJob).to have_been_enqueued
        response.should redirect_to(new_background_job_path)
      end
    end
  end

  context "when not signed in" do
    describe "#new" do
      it 'has 302 found' do
        get :new
        response.should redirect_to(new_user_session_path.split('?').first)
      end
    end
  end
end
