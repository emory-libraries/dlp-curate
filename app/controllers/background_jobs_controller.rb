# frozen_string_literal: true
class BackgroundJobsController < ApplicationController
  with_themed_layout 'dashboard'
  def new; end

  def create
    if params[:jobs].include?('_preprocessor')
      preprocessor_actions
    else
      process_non_preprocessor_jobs
    end
  end

  private

    def process_non_preprocessor_jobs
      if params[:jobs] == 'cleanup'
        FileSetCleanUpJob.perform_later
        redirect_to new_background_job_path, notice: "File Set Cleanup Job has started successfully."
      elsif params[:jobs] == 'work_members_cleanup'
        process_work_members_cleanup(params[:work_members_cleanup_text])
      elsif params[:jobs] == 'preservation'
        generic_csv_action(params[:preservation_csv], PreservationWorkflowImporterJob)
        redirect_to new_background_job_path, notice: "Preservation Workflow Importer Job has started successfully."
      elsif params[:jobs] == 'aws_fixity'
        generic_csv_action(params[:aws_fixity_csv], ProcessAwsFixityPreservationEventsJob)
        redirect_to new_background_job_path, notice: "AWS Fixity Preservation Events Importer Job has been added to the queue."
      else
        reindex_objects_action
        redirect_to new_background_job_path, notice: "Reindex Files Job has started successfully."
      end
    end

    def reindex_objects_action
      CSV.foreach(params[:reindex_csv].path, headers: true) do |row|
        r = row.to_h
        ReindexObjectJob.perform_later(r['id'])
      end
    end

    def preprocessor_actions
      if params[:jobs].include?('dams')
        preprocessor_action(
          params[:dams_csv] && params[:dams_importer],
          DamsPreprocessor.new(params[:dams_csv].path, params[:dams_importer])
        )
      elsif params[:jobs].include?('lang')
        preprocessor_action(
          params[:lang_csv] && params[:lang_importer],
          LangmuirPreprocessor.new(params[:lang_csv].path, params[:lang_importer])
        )
      else
        process_yellowback
      end
    end

    def process_yellowback
      preprocessor_action(
        params[:book_csv] && params[:book_xml] && params[:book_map] && params[:book_importer],
        YellowbackPreprocessor.new(
          params[:book_csv].path,
          params[:book_xml].path,
          params[:book_importer],
          params[:book_map].to_sym,
          params[:book_start_num].to_i,
          params[:add_transcript],
          params[:add_ocr_output]
        )
      )
    end

    def preprocessor_action(guard_test, preprocessor)
      raise "This preprocessor requires a CSV file." unless guard_test
      preprocessor = preprocessor
      preprocessor.merge
      respond_to do |format|
        format.any { send_file preprocessor.processed_csv, filename: "processed_file.csv" }
      end
    rescue => error
      "This preprocessor has encountered an error: #{error}"
    end

    def generic_csv_action(csv_param, job_class)
      name = csv_param.original_filename
      path = Rails.root.join('tmp', name)
      File.open(path, "w+") { |f| f.write(csv_param.read) }
      job_class.perform_later(path.to_s)
    end

    def process_work_members_cleanup(text_from_box)
      if text_from_box.length < 14
        redirect_to new_background_job_path, alert: 'Please enter at least one Work ID in the text box.'
      else
        WorkMembersCleanUpJob.perform_later(text_from_box)
        redirect_to new_background_job_path, notice: "Work Members Cleanup Job has been added to the queue."
      end
    end
end
