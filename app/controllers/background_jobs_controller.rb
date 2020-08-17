# frozen_string_literal: true
class BackgroundJobsController < ApplicationController
  with_themed_layout 'dashboard'
  def new; end

  def create
    if params[:jobs] == 'cleanup'
      FileSetCleanUpJob.perform_later
      msg = "File Set Cleanup Job"
    elsif params[:jobs] == 'preservation'
      PreservationWorkflowImporterJob.perform_later(params[:preservation_csv].path)
      msg = "Preservation Workflow Importer Job"
    else
      CSV.foreach(params[:reindex_csv].path, headers: true) do |row|
        r = row.to_h
        ReindexObjectJob.perform_later(r['id'])
      end
      msg = "Reindex Files Job"
    end
    flash_message = msg + " has started successfully."
    redirect_to new_background_job_path, notice: flash_message
  end
end
