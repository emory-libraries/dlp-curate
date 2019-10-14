# Generated by hyrax:models:install
class FileSet < ActiveFedora::Base
  require 'noid-rails'
  PRIMARY = 'Primary Content'.freeze
  SUPPLEMENTAL = 'Supplemental Content'.freeze
  PRESERVATION = 'Supplemental Preservation'.freeze

  def assign_id
    service.mint + Rails.configuration.x.curate_template
  end

  property :pcdm_use, predicate: 'http://pcdm.org/use', multiple: false do |index|
    index.as :facetable
  end

  property :file_type, predicate: 'http://purl.org/dc/elements/1.1/format', multiple: false do |index|
    index.as :facetable
  end

  property :preservation_event, predicate: "http://metadata.emory.edu/vocab/cor-terms#preservation_event", class_name: "PreservationEvent"

  def primary?
    pcdm_use == PRIMARY
  end

  def supplementary?
    !primary?
  end

  def original_file
    preservation_master_file
  end

  include ::Hyrax::FileSetBehavior
  self.indexer = Curate::FileSetIndexer

  directly_contains_one :preservation_master_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#PreservationMasterFile'), class_name: 'Hydra::PCDM::File'
  directly_contains_one :service_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#ServiceFile'), class_name: 'Hydra::PCDM::File'
  directly_contains_one :intermediate_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#IntermediateFile'), class_name: 'Hydra::PCDM::File'
  directly_contains_one :transcript_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#Transcript'), class_name: 'Hydra::PCDM::File'
  directly_contains_one :extracted, through: :files, type: ::RDF::URI('http://metadata.emory.edu/vocab/cor-terms#fileuseExtractedText'), class_name: 'Hydra::PCDM::File'

  private

    def service
      @service ||= Noid::Rails::Service.new
    end
end
