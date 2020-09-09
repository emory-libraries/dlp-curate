# frozen_string_literal: true
class BackgroundJobsController < ApplicationController
  with_themed_layout 'dashboard'
  def new; end

  def create
    if params[:jobs] == 'cleanup'
      FileSetCleanUpJob.perform_later
      msg = "File Set Cleanup Job"
    elsif params[:jobs] == 'preservation'
      name = params[:preservation_csv].original_filename
      path = Rails.root.join('tmp', 'uploads', name)
      File.open(path, "w+") { |f| f.write(params[:preservation_csv].read) }
      PreservationWorkflowImporterJob.perform_later(path)
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
