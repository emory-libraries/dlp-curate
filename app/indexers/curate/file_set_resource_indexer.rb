# frozen_string_literal: true

# Valkyrie indexer for FileSetResource.
# Mirrors the custom Solr fields from the AF Curate::FileSetIndexer.
module Curate
  class FileSetResourceIndexer < Hyrax::Indexers::FileSetIndexer
    include Hyrax::Indexer(:emory_file_set_metadata)

    def to_solr
      super.tap do |solr_doc|
        solr_doc['pcdm_use_tesim'] = resource.pcdm_use if resource.pcdm_use.present?
        solr_doc['alternate_ids_ssim'] = resource.alternate_ids.map(&:id) if resource.respond_to?(:alternate_ids)

        index_preservation_events(solr_doc)
        index_file_metadata(solr_doc)
        index_full_text(solr_doc)
      end
    end

    private

    def index_preservation_events(solr_doc)
      if resource.respond_to?(:preservation_events)
        solr_doc['preservation_event_tesim'] = resource.preservation_events.map(&:preservation_event_terms)
      elsif resource.preservation_event_ids.present?
        solr_doc['preservation_event_ids_tesim'] = Array(resource.preservation_event_ids)
      end
    rescue StandardError => e
      Rails.logger.warn("FileSetResourceIndexer: could not index preservation events: #{e.message}")
    end

    def index_file_metadata(solr_doc)
      file_metadata = primary_file_metadata
      return unless file_metadata

      solr_doc['file_path_ssim'] = file_metadata.file_path if file_metadata.respond_to?(:file_path) && file_metadata.file_path.present?
      solr_doc['creating_application_name_ssim'] = file_metadata.creating_application_name if file_metadata.respond_to?(:creating_application_name) && file_metadata.creating_application_name.present?
      solr_doc['creating_os_ssim'] = file_metadata.creating_os if file_metadata.respond_to?(:creating_os) && file_metadata.creating_os.present?
      solr_doc['puid_ssim'] = file_metadata.puid if file_metadata.respond_to?(:puid) && file_metadata.puid.present?
      solr_doc['original_checksum_ssim'] = file_metadata.original_checksum if file_metadata.respond_to?(:original_checksum) && file_metadata.original_checksum.present?
      solr_doc['file_name_ssim'] = file_metadata.original_filename if file_metadata.respond_to?(:original_filename) && file_metadata.original_filename.present?
      solr_doc['file_size_ssim'] = file_metadata.file_size if file_metadata.respond_to?(:file_size) && file_metadata.file_size.present?
    end

    def index_full_text(solr_doc)
      text_content = resource.extracted_text_content if resource.respond_to?(:extracted_text_content)
      return unless text_content.present?

      solr_doc['alto_xml_tesi'] = text_content if text_content.include?('<alto')
      solr_doc['transcript_text_tesi'] = text_content unless text_content.include?('<alto')
    rescue StandardError => e
      Rails.logger.warn("FileSetResourceIndexer: could not index full text: #{e.message}")
    end

    def primary_file_metadata
      Hyrax.config.file_set_file_service.new(file_set: resource).primary_file
    rescue StandardError
      nil
    end
  end
end
