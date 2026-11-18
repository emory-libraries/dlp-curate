# frozen_string_literal: true

# Valkyrie indexer for FileSetResource.
# Mirrors the custom Solr fields from the AF Curate::FileSetIndexer.
module Curate
  class FileSetResourceIndexer < Hyrax::Indexers::FileSetIndexer
    include Hyrax::Indexer(:emory_file_set_metadata)

    def to_solr
      super.tap do |solr_doc|
        solr_doc['pcdm_use_tesim'] = resource.pcdm_use if resource.pcdm_use.present?
        index_label(solr_doc)
        # Temporary: index alternate_ids for remediation query discovery.
        # Remove after running migrate_alternate_ids_to_emory_persistent_id.
        solr_doc['alternate_ids_ssim'] = resource.alternate_ids.map(&:id) if resource.respond_to?(:alternate_ids) && resource.alternate_ids.present?
        solr_doc['preservation_event_tesim'] = resource.preservation_event.map(&:preservation_event_terms) if resource.preservation_event.present?

        index_file_metadata(solr_doc)
        index_full_text(solr_doc)
      end
    end

    private

      # As the AF Hyrax::FileSetIndexer does; SolrDocument#label (and so the
      # manifest's download labels) read label_tesim.
      def index_label(solr_doc)
        return if resource.label.blank?

        solr_doc['label_tesim'] = resource.label
        solr_doc['label_ssi'] = resource.label
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
        index_fm_field(solr_doc, fm, :date_created, 'date_created_ssim')
        index_alpha_channels(solr_doc, fm)
      end

      # Hyrax fills alpha_channels_ssi from the FITS `channels` value (the audio
      # channel count, still indexed as channels_tesim). As with the AF indexer,
      # Curate uses it for the ImageMagick-detected `alpha_channels` instead.
      def index_alpha_channels(solr_doc, fm)
        solr_doc.delete('alpha_channels_ssi')
        alpha_channels = fm.respond_to?(:alpha_channels) ? Array(fm.alpha_channels) : []
        solr_doc['alpha_channels_ssi'] = alpha_channels.first if alpha_channels.present?
      end

      def index_fm_field(solr_doc, fm, attr, solr_key)
        return unless fm.respond_to?(attr)
        val = fm.public_send(attr)
        solr_doc[solr_key] = val if val.present?
      end

      # All fields assigned here are utilized by BlacklightIiifSearch, as in the AF Curate::FileSetIndexer.
      def index_full_text(solr_doc)
        transcript = text_file_content(:find_transcript_file, '.txt')
        solr_doc['transcript_text_tesi'] = transcript if transcript.present?

        alto_xml = text_file_content(:find_extracted_text, '.xml')
        solr_doc['alto_xml_tesi'] = alto_json(alto_xml) if alto_xml.present?

        parent = Hyrax.custom_queries.find_parent_work(resource:)
        solr_doc['is_page_of_ssi'] = parent.id.to_s if parent
      rescue StandardError => e
        Rails.logger.warn("FileSetResourceIndexer: could not index full text: #{e.message}")
      end

      # @return [String, nil] the content of the FileSet's file found by the custom query,
      #   when its file name has the expected extension.
      def text_file_content(query, extension)
        file_metadata = Hyrax.custom_queries.public_send(query, file_set: resource)
        return unless Array(file_metadata.original_filename).first.to_s.include?(extension)

        file_metadata.content&.force_encoding('UTF-8')&.encode('UTF-8', invalid: :replace, replace: '')
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      def alto_json(alto_xml)
        fm = primary_file_metadata
        Curate::TextExtraction::AltoReader.new(alto_xml, Array(fm&.width).first, Array(fm&.height).first).json
      end

      def primary_file_metadata
        Hyrax.config.file_set_file_service.new(file_set: resource).primary_file
      rescue StandardError
        nil
      end
  end
end
