module Curate
  class FileSetPresenter < Hyrax::FileSetPresenter
    delegate :pcdm_use, to: :solr_document
  end
end
