# frozen_string_literal: true

class DerivativesController < ApplicationController
  before_action :authenticate_user!

  def clean_up
    FileSetCleanUpJob.perform_later(params[:file_set_id])
    flash[:notice] = "Your update request has been submitted and may take several minutes to complete"
    redirect_to hyrax_file_set_path(params[:file_set_id])
  end
end
