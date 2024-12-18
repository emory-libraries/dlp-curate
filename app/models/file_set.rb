# frozen_string_literal: true

# Generated by hyrax:models:install
class FileSet < ActiveFedora::Base
  require 'noid-rails'
  PRIMARY = 'Primary Content'
  SUPPLEMENTAL = 'Supplemental Content'
  PRESERVATION = 'Supplemental Preservation'

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

  property :deduplication_key, predicate: "http://metadata.emory.edu/vocab/predicates#deduplicationKey", multiple: false do |index|
    index.as :stored_searchable
  end

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
  include PreservationEvents
  self.indexer = Curate::FileSetIndexer

  directly_contains_one :preservation_master_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#PreservationMasterFile'), class_name: 'Hydra::PCDM::File'
  directly_contains_one :service_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#ServiceFile'), class_name: 'Hydra::PCDM::File'
  directly_contains_one :intermediate_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#IntermediateFile'), class_name: 'Hydra::PCDM::File'
  directly_contains_one :transcript_file, through: :files, type: ::RDF::URI('http://pcdm.org/use#Transcript'), class_name: 'Hydra::PCDM::File'
  directly_contains_one :extracted, through: :files, type: ::RDF::URI('http://metadata.emory.edu/vocab/cor-terms#fileuseExtractedText'), class_name: 'Hydra::PCDM::File'

  accepts_nested_attributes_for :preservation_event,
                                allow_destroy: true,
                                reject_if:     proc { |attrs|
                                                 ['event_id', 'event_type', 'work_id', 'initiating_user',
                                                  'event_start', 'event_end', 'outcome', 'fileset_id',
                                                  'software_version', 'workflow_id', 'event_details'].all? do |key|
                                                   Array(attrs[key]).all?(&:blank?)
                                                 end
                                               }

  # We override this method which comes from Hydra::Works::VirusCheck and
  # is mixed-in through ::Hyrax::FileSetBehavior on L#34
  def viruses?
    return false unless preservation_master_file&.new_record? # We have a new file to check
    event_start = DateTime.current
    # This method updated to match v3.0.0.rc1
    result = Hyrax::VirusCheckerService.file_has_virus?(preservation_master_file)
    file_set = FileSet.find(preservation_master_file.id&.partition("/files")&.first)
    event = { 'type' => 'Virus Check', 'start' => event_start, 'outcome' => result, 'software_version' => 'ClamAV 0.101.4', 'user' => file_set.depositor }
    if result == false
      event['details'] = 'No viruses found'
      event['outcome'] = 'Success'
    else
      event['details'] = "Virus was found in file: #{preservation_master_file&.original_name}"
      event['outcome'] = 'Failure'
    end
    create_preservation_event(file_set, event)
    result
  end

  def preferred_file
    if service_file.present?
      :service_file
    elsif intermediate_file.present?
      :intermediate_file
    else
      :preservation_master_file
    end
  end

  # The two methods below err when storing text in Solr, so forcing UTF-8 encoding removes errant text (most likely ASCII).
  def alto_xml
    return extracted&.content&.encode("UTF-8", invalid: :replace, replace: "") if extracted&.file_name&.first&.include?('.xml')
    nil
  end

  def transcript_text
    transcript_file&.content&.encode("UTF-8", invalid: :replace, replace: "") if transcript_file&.file_name&.first&.include?('.txt')
  end

  private

    def service
      @service ||= Noid::Rails::Service.new
    end
end
