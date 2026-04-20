# frozen_string_literal: true

class CharacterizationController < ApplicationController
  before_action :authenticate_user!

  # Triggers re-characterization on a FileSet's primary/original file.
  # Supports both ActiveFedora and Valkyrie file sets during lazy migration.
  def re_characterize
    ReCharacterizeJob.perform_later(file_set: load_file_set, user: current_user.uid)
    flash[:notice] = "The Re-characterization request has been submitted and may take several minutes to complete"
    redirect_to hyrax_file_set_path(params[:file_set_id])
  end

  private

    def load_file_set
      if Hyrax.config.valkyrie_transition?
        Hyrax.query_service.find_by(id: params[:file_set_id])
      else
        FileSet.find(params[:file_set_id])
      end
    end
end
