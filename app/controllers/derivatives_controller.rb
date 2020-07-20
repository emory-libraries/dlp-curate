# frozen_string_literal: true

class DerivativesController < ApplicationController
  before_action :authenticate_user!

  def clean_up
    FileSetCleanUpJob.perform_later(params[:file_set_id])
  end
end
