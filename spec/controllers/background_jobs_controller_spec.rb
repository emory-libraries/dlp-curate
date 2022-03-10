# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackgroundJobsController, type: :controller, clean: true do
  include ActionDispatch::TestProcess
  include ActiveJob::TestHelper

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:csv_file) { fixture_file_upload((fixture_path + '/reindex_files.csv'), 'text/csv') }
  let(:csv_file2) do
    fixture_file_upload((fixture_path + '/preservation_workflows.csv'), 'text/csv')
  end
  let(:csv_file3) do
    fixture_file_upload((fixture_path + '/csv_import/aws_fixity_test.csv'), 'text/csv')
  end
  let(:new_call) { get :new }

  context "when signed in" do
    before do
      sign_in admin
    end

    # Needed since Jobs were still in queue when next test started, throwing errors.
    after do
      clear_enqueued_jobs
    end

    describe "#new" do
      it 'has 200 code for new' do
        new_call
        expect(response.status).to eq(200)
      end
    end

    describe "#create" do
      let(:cleanup) { post :create, params: { jobs: 'cleanup', format: 'json' } }
      let(:preservation) do
        post :create, params: { jobs: 'preservation', preservation_csv: csv_file2, format: 'json' }
      end
      let(:reindex) { post :create, params: { jobs: 'reindex', reindex_csv: csv_file, format: 'json' } }
      let(:aws_fixity) do
        post :create, params: { jobs: 'aws_fixity', aws_fixity_csv: csv_file3, format: 'json' }
      end

      it "successfully starts a file_set cleanup background job" do
        expect(cleanup).to redirect_to(new_background_job_path)
      end

      it "successfully starts a preservation workflow background job" do
        expect(preservation).to redirect_to(new_background_job_path)
        expect(PreservationWorkflowImporterJob).to have_been_enqueued
      end

      it "successfully starts a reindex background job" do
        expect(reindex).to redirect_to(new_background_job_path)
        # Needed to call out how many times the job will be enqueued.
        expect(ReindexObjectJob).to have_been_enqueued.twice
      end

      it "successfully starts a AWS fixity background job" do
        expect(aws_fixity).to redirect_to(new_background_job_path)
        expect(ProcessAwsFixityPreservationEventsJob).to have_been_enqueued
      end

      context 'books preprocessor' do
        let(:preprocessor) { instance_double(YellowbackPreprocessor) }
        let(:yellowback_pull_list_sample) do
          fixture_file_upload('csv_import/yellowbacks/yellowbacks_pull_list.csv', 'text/csv')
        end
        let(:alma_export_sample) do
          fixture_file_upload('csv_import/yellowbacks/yellowbacks_marc.xml', 'text/xml')
        end

        it 'goes through the expected processes' do
          allow(preprocessor).to receive(:processed_csv)
          expect(YellowbackPreprocessor).to receive(:new).with(any_args).and_return(preprocessor)
          expect(preprocessor).to receive(:merge)
          post :create, params: { jobs: 'book_preprocessor', book_csv: yellowback_pull_list_sample, book_xml: alma_export_sample, book_map: 'limb', format: 'json' }
        end
      end

      context 'langmuir preprocessor' do
        let(:preprocessor) { instance_double(LangmuirPreprocessor) }
        let(:langmuir_sample) do
          fixture_file_upload('csv_import/langmuir/langmuir-unprocessed.csv', 'text/csv')
        end

        it 'goes through the expected processes' do
          allow(preprocessor).to receive(:processed_csv)
          expect(LangmuirPreprocessor).to receive(:new).with(any_args).and_return(preprocessor)
          expect(preprocessor).to receive(:merge)
          post :create, params: { jobs: 'lang_preprocessor', lang_csv: langmuir_sample, format: 'json' }
        end
      end

      context 'DAMS preprocessor' do
        let(:preprocessor) { instance_double(DamsPreprocessor) }
        let(:dams_sample) do
          fixture_file_upload('csv_import/dams/dams-unprocessed.csv', 'text/csv')
        end

        it 'goes through the expected processes' do
          allow(preprocessor).to receive(:processed_csv)
          expect(DamsPreprocessor).to receive(:new).with(any_args).and_return(preprocessor)
          expect(preprocessor).to receive(:merge)
          post :create, params: { jobs: 'dams_preprocessor', dams_csv: dams_sample, format: 'json' }
        end
      end
    end
  end

  context "when not signed in" do
    describe "#new" do
      it 'has 302 found' do
        expect(new_call).to redirect_to(new_user_session_path.split('?').first)
      end
    end
  end
end
