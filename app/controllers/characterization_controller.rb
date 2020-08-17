# frozen_string_literal: true

class CharacterizationController < ApplicationController
  before_action :authenticate_user!

  def re_characterize
    file_set = FileSet.find(params[:file_set_id])
    CharacterizeJob.perform_later(file_set, nil, file_set.file_path.first, user: current_user.uid)
    flash[:notice] = "The Re-characterization request has been submitted and may take several minutes to complete"
    redirect_to hyrax_file_set_path(params[:file_set_id])
  end
end
