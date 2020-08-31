# frozen_string_literal: true

class CharacterizationController < ApplicationController
  before_action :authenticate_user!

  def re_characterize
    file_set = FileSet.find(params[:file_set_id])
    ReCharacterizeJob.perform_later(file_set: file_set, user: current_user)
    flash[:notice] = "The Re-characterization request has been submitted and may take several minutes to complete"
    redirect_to hyrax_file_set_path(params[:file_set_id])
  end
end
