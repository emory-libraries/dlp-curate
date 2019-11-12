module Curate
  class FileSetPresenter < Hyrax::FileSetPresenter
    delegate :pcdm_use, to: :solr_document
    delegate :file_name, to: :solr_document
    delegate :file_path, to: :solr_document
    delegate :file_size, to: :solr_document
    delegate :created, to: :solr_document
    delegate :valid, to: :solr_document
    delegate :well_formed, to: :solr_document
    delegate :creating_application_name, to: :solr_document
    delegate :puid, to: :solr_document
    delegate :date_modified, to: :solr_document
    delegate :character_set, to: :solr_document
    delegate :byte_order, to: :solr_document
    delegate :color_space, to: :solr_document
    delegate :compression, to: :solr_document
    delegate :profile_name, to: :solr_document
    delegate :profile_version, to: :solr_document
  end
end
