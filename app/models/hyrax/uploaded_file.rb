# frozen_string_literal: true

# [Hyrax-overwrite-v3.4.2]

module Hyrax
  ##
  # Store a file uploaded by a user.
  #
  # Eventually these files get attached to {FileSet}s and pushed into Fedora.
  class UploadedFile < ApplicationRecord
    self.table_name = 'uploaded_files'
    mount_uploader :service_file, UploadedFileUploader
    mount_uploader :preservation_master_file, UploadedFileUploader
    mount_uploader :intermediate_file, UploadedFileUploader
    mount_uploader :extracted_text, UploadedFileUploader
    mount_uploader :transcript, UploadedFileUploader
    mount_uploader :collection_banner, UploadedFileUploader
    # mount_uploader :file, UploadedFileUploader
    # alias uploader file
    has_many :job_io_wrappers,
             inverse_of: 'uploaded_file',
             class_name: 'JobIoWrapper',
             dependent:  :destroy
    belongs_to :user, class_name: '::User'

    ##
    # Associate a {FileSet} with this uploaded file.
    #
    # @param [Hyrax::Resource, ActiveFedora::Base] file_set
    # @return [void]
    def add_file_set!(file_set)
      uri = case file_set
            when ActiveFedora::Base
              file_set.uri
            when Hyrax::Resource
              file_set.id
            end
      update!(file_set_uri: uri)
    end

    def uploader
      files = [service_file, preservation_master_file, intermediate_file, extracted_text, transcript, collection_banner]
      files.find(&:present?)
    end
  end
end
