# frozen_string_literal: true

module Curate
  class FileSetPresenter < Hyrax::FileSetPresenter
    delegate :pcdm_use, :file_name, :file_path, :file_size, :created, :valid, :well_formed,
             :creating_application_name, :puid, :date_modified, :character_set,
             :byte_order, :color_space, :compression, :profile_name, :profile_version, to: :solr_document
  end
end
