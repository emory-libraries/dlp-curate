# frozen_string_literal: true

# [Hyrax-overwrite-v3.4.1]
module Hyrax
  class UploadsController < ApplicationController
    load_and_authorize_resource class: Hyrax::UploadedFile

    def create
      @upload.attributes = { file:                     params[:file_name],
                             preservation_master_file: params[:preservation_master_file],
                             intermediate_file:        params[:intermediate_file],
                             service_file:             params[:service_file],
                             extracted_text:           params[:extracted_text],
                             transcript:               params[:transcript],
                             fileset_use:              params[:fileset_use],
                             collection_banner:        params[:collection_banner],
                             user:                     current_user }
      @upload.save!
    end

    def destroy
      @upload.destroy
      head :no_content
    end
  end
end
