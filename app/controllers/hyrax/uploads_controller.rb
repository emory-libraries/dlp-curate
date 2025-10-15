# frozen_string_literal: true

# [Hyrax-overwrite-hyrax-v5.1.0]
module Hyrax
  class UploadsController < ApplicationController
    load_and_authorize_resource class: Hyrax::UploadedFile

    def create
      if params[:id].blank?
        @upload.attributes = upload_attributes
      else
        upload_with_chunking
      end

      @upload.save!
    end

    def destroy
      @upload.destroy
      head :no_content
    end

    private

    def upload_attributes
      returned_attributes = {}
      returned_attributes[:file] = params[:file_name]
      returned_attributes[:preservation_master_file] = params[:preservation_master_file]
      returned_attributes[:intermediate_file] = params[:intermediate_file]
      returned_attributes[:service_file] = params[:service_file]
      returned_attributes[:extracted_text] = params[:extracted_text]
      returned_attributes[:transcript] = params[:transcript]
      returned_attributes[:fileset_use] = params[:fileset_use]
      returned_attributes[:collection_banner] = params[:collection_banner]
      returned_attributes[:user] = current_user
      returned_attributes
    end

    def upload_with_chunking
      @upload = Hyrax::UploadedFile.find(params[:id])
      unpersisted_upload = Hyrax::UploadedFile.new(upload_attributes)

      # Check if CONTENT-RANGE header is present
      content_range = request.headers['CONTENT-RANGE']
      return @upload.file = unpersisted_upload.file if content_range.nil?

      # deal with chunks
      current_size = @upload.file.size
      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i # "bytes 100-999999/1973660678" will return '100'

      # Add the following chunk to the incomplete upload
      if @upload.file.present? && begin_of_chunk == current_size
        File.open(@upload.file.path, "ab") { |f| f.write(params[:files].first.read) }
      else
        @upload.file = unpersisted_upload.file
      end
    end
  end
end
