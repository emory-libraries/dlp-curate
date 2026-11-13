# frozen_string_literal: true

module ManifestJsonJbuilderHelper
  # Loads a file set by ID with fallback: Valkyrie query service first (handles
  # both Fedora 6 and AF via Wings), then direct AF lookup as a last resort.
  def find_file_set_by_id(child_id)
    if Hyrax.config.valkyrie_transition?
      begin
        Hyrax.query_service.find_by(id: child_id)
      rescue Valkyrie::Persistence::ObjectNotFoundError, Ldp::HttpError, Ldp::BadRequest, Faraday::Error
        nil
      end
    end || FileSet.find(child_id)
  end

  def enable_search
    @image_concerns.any? { |id| SolrDocument&.find(id)&.[]('alto_xml_tesi')&.present? } && @solr_doc['all_text_tsimv'].present?
  end

  def file_set_has_image_to_display(file_set)
    mime = file_set_mime_type(file_set)
    visibility = file_set_visibility(file_set)

    (file_set.preservation_master_file.present? || find_original_file_metadata(file_set).present?) &&
      mime.present? && !unwanted_mime_types.any? { |m| mime.include?(m) } &&
      visibility.present? && visibility != 'restricted'
  end

  def find_canvas_width_and_height(file_set)
    if file_set.is_a?(Hyrax::Resource)
      process_valkyrie_canvas_width(file_set)
    else
      [file_set.original_file&.width, file_set.original_file&.height]
    end
  end

  private

    # Valkyrie helper: get mime_type from the original file's FileMetadata,
    # falling back to Solr for AF-origin file sets that lack Valkyrie FileMetadata.
    def find_original_file_metadata(file_set)
      Hyrax.custom_queries
           .find_many_file_metadata_by_use(resource: file_set, use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
           .first
    rescue StandardError
      nil
    end

    def find_file_set_solr_doc(file_set)
      SolrDocument.find(file_set.id.to_s)
    rescue Blacklight::Exceptions::RecordNotFound
      nil
    end

    def unwanted_mime_types
      ['pdf', 'xml', 'text']
    end

    def file_set_mime_type(file_set)
      file_set.is_a?(Hyrax::Resource) ? find_file_set_mime_type_from_metadata(file_set) : file_set.mime_type
    end

    # Determines visibility for a file set with a Solr-based fallback.
    # Wings-wrapped AF file sets can fail on the permission_manager path
    # during lazy migration, so we fall back to the indexed visibility.
    def file_set_visibility(file_set)
      file_set.visibility
    rescue StandardError
      solr_doc = find_file_set_solr_doc(file_set)
      solr_doc&.[]('visibility_ssi') || 'restricted'
    end

    def find_file_set_mime_type_from_metadata(file_set)
      file_metadata = find_original_file_metadata(file_set)
      return file_metadata.mime_type.to_s if file_metadata&.mime_type.present?

      solr_doc = find_file_set_solr_doc(file_set)
      solr_doc&.[]('mime_type_ssi').to_s
    end

    def process_valkyrie_canvas_width(file_set)
      original_fm = find_original_file_metadata(file_set)
      width  = original_fm&.width&.first
      height = original_fm&.height&.first

      if width.nil? || height.nil?
        fs_solr = find_file_set_solr_doc(file_set)
        width  ||= fs_solr&.[]('width_is')
        height ||= fs_solr&.[]('height_is')
      end

      [width, height]
    end
end
