# frozen_string_literal: true

class FullTextIndexingController < ApplicationController
  before_action :authenticate_user!

  def full_text_index
    call_compiling_job
    redirect_to hyrax_curate_generic_work_path(params[:work_id]), notice: "Full-Text Indexing has been queued for this work."
  end

  def full_text_index_with_pages
    reindex_work_child_members
    call_compiling_job
    redirect_to hyrax_curate_generic_work_path(params[:work_id]), notice: "Full-Text Indexing has been queued for this work."
  end

  private

    def call_compiling_job
      CompileFullTextJob.perform_later(work_id: params[:work_id], user_id: params[:user_id].to_i)
    end

    def reindex_work_child_members
      ReindexObjectChildrenJob.perform_later(params[:work_id])
    end
end
