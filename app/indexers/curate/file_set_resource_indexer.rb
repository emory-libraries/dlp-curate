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
        fm = primary_file_metadata
        return unless fm

        index_fm_field(solr_doc, fm, :file_path, 'file_path_ssim')
        index_fm_field(solr_doc, fm, :creating_application_name, 'creating_application_name_ssim')
        index_fm_field(solr_doc, fm, :creating_os, 'creating_os_ssim')
        index_fm_field(solr_doc, fm, :puid, 'puid_ssim')
        index_fm_field(solr_doc, fm, :original_checksum, 'original_checksum_ssim')
        index_fm_field(solr_doc, fm, :original_filename, 'file_name_ssim')
        index_fm_field(solr_doc, fm, :file_size, 'file_size_ssim')
      end

      def index_fm_field(solr_doc, fm, attr, solr_key)
        return unless fm.respond_to?(attr)
        val = fm.public_send(attr)
        solr_doc[solr_key] = val if val.present?
      end

      def index_full_text(solr_doc)
        text_content = resource.extracted_text_content if resource.respond_to?(:extracted_text_content)
        return if text_content.blank?

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
