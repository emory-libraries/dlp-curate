# frozen_string_literal: true

# Valkyrie helper: get mime_type from the original file's FileMetadata
find_original_file_metadata = lambda { |fs|
  Hyrax.custom_queries
       .find_many_file_metadata_by_use(resource: fs, use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
       .first
}

find_file_set_mime_type = lambda { |fs|
  fm = find_original_file_metadata.call(fs)
  fm&.mime_type.to_s
}

json.set! :@context, 'http://iiif.io/api/presentation/2/context.json'
json.set! :@type, 'sc:Manifest'
json.set! :@id, @root_url
json.label @solr_doc.title.first

json.metadata @manifest_metadata do |child|
  json.label child['label']
  json.value child['value']
end

enable_search = @image_concerns.any? { |id| SolrDocument&.find(id)&.[]('alto_xml_tesi')&.present? } && @solr_doc['all_text_tsimv'].present?
# The code block below activates the IIIF Search tools within the
#   Universal Viewer. This will use the presence of all_text_tsimv values
#   within the Work to activate, but each text-optimized FileSet's alto_xml_tesi,
#   transcript_text_tesi, and is_page_of_ssi fields must also be indexed for normal
#   searching functions.
if enable_search
  json.service do
    json.child! do
      json.set! :@context, 'http://iiif.io/api/search/0/context.json'
      json.set! :@id, @solr_doc.work_iiif_search_url
      json.profile 'http://iiif.io/api/search/0/search'
      json.label 'Search within this item'
    end
  end
end

json.sequences [''] do
  json.set! :@type, 'sc:Sequence'
  json.set! :@id, "#{@root_url}/sequence/normal"
  json.rendering @manifest_rendering do |child|
    json.set! :@id, child['@id']
    json.format child['format']
    json.label child['label']
  end
  json.canvases @image_concerns do |child_id|
    file_set = if Hyrax.config.valkyrie_transition?
                 Hyrax.query_service.find_by(id: child_id)
               else
                 FileSet.find(child_id)
               end
    mime_types = ['pdf', 'xml', 'text']
    file_set_mime = file_set.is_a?(Hyrax::Resource) ? find_file_set_mime_type.call(file_set) : file_set.mime_type
    unless mime_types.any? { |m| file_set_mime&.include?(m) } || file_set.visibility == 'restricted'
      child_iiif_service = ManifestBuilderService.new(curation_concern: file_set)
      canvas_uri = "#{@root_url}/canvas/#{child_id}"
      json.set! :@id, canvas_uri
      json.set! :@type, 'sc:Canvas'
      json.label Array(file_set.title).first
      if file_set.is_a?(Hyrax::Resource)
        original_fm = find_original_file_metadata.call(file_set)
        json.width original_fm&.width&.first
        json.height original_fm&.height&.first
      else
        json.width file_set.original_file&.width
        json.height file_set.original_file&.height
      end
      json.images [file_set] do
        json.set! :@type, 'oa:Annotation'
        json.motivation 'sc:painting'
        json.resource do
          json.set! :@type, 'dctypes:Image'
          json.set! :@id, child_iiif_service.iiif_url
          json.width 640
          json.height 480
          json.service do
            json.set! :@context, 'http://iiif.io/api/image/2/context.json'
            info_url = child_iiif_service.info_url
            json.set! :@id, info_url
            json.profile 'http://iiif.io/api/image/2/level2.json'
          end
        end
        json.on canvas_uri
      end
    end
  end
end
