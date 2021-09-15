# frozen_string_literal: true
class BackgroundJobsController < ApplicationController
  with_themed_layout 'dashboard'
  def new; end

  def create
    if params[:jobs] == 'cleanup'
      FileSetCleanUpJob.perform_later
      redirect_to new_background_job_path, notice: "File Set Cleanup Job has started successfully."
    elsif params[:jobs] == 'preservation'
      preservation_worklow_action
      redirect_to new_background_job_path, notice: "Preservation Workflow Importer Job has started successfully."
    elsif params[:jobs].include?('_preprocessor')
      preprocessor_actions
    else
      reindex_objects_action
      redirect_to new_background_job_path, notice: "Reindex Files Job has started successfully."
    end
  end

  private

    def preservation_worklow_action
      name = params[:preservation_csv].original_filename
      path = Rails.root.join('tmp', name)
      File.open(path, "w+") { |f| f.write(params[:preservation_csv].read) }
      PreservationWorkflowImporterJob.perform_later(path.to_s)
    end

    def reindex_objects_action
      CSV.foreach(params[:reindex_csv].path, headers: true) do |row|
        r = row.to_h
        ReindexObjectJob.perform_later(r['id'])
      end
    end

    def preprocessor_actions
      if params[:jobs].include?('dams')
        preprocessor_action(params[:dams_csv].present?, DamsPreprocessor.new(params[:dams_csv].path))
      elsif params[:jobs].include?('lang')
        preprocessor_action(params[:lang_csv].present?, LangmuirPreprocessor.new(params[:lang_csv].path))
      else
        preprocessor_action(
          params[:book_csv] && params[:book_xml] && params[:book_map],
          YellowbackPreprocessor.new(
            params[:book_csv].path,
            params[:book_xml].path,
            params[:book_repl],
            params[:book_map].to_sym,
            params[:book_start_num].to_i
          )
        )
      end
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
end
