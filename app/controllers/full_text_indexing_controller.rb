# frozen_string_literal: true

class FullTextIndexingController < ApplicationController
  before_action :authenticate_user!

  def full_text_index
    CompileFullTextJob.perform_later(work_id: params[:work_id], user_id: params[:user_id].to_i)
    redirect_to hyrax_curate_generic_work_path(params[:work_id]), notice: "Full-Text Indexing has been queued for this work."
  end
end
