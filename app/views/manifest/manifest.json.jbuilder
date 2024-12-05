# frozen_string_literal: true

json.set! :@context, 'http://iiif.io/api/presentation/2/context.json'
json.set! :@type, 'sc:Manifest'
json.set! :@id, @root_url
json.label @solr_doc.title.first

json.metadata @manifest_metadata do |child|
  json.label child['label']
  json.value child['value']
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
    file_set = FileSet.find(child_id)
    mime_types = ['pdf', 'xml', 'text']
    unless mime_types.any? { |m| file_set.mime_type&.include?(m) } || file_set.visibility == 'restricted'
      child_iiif_service = ManifestBuilderService.new(curation_concern: file_set)
      canvas_uri = "#{@root_url}/canvas/#{child_id}"
      json.set! :@id, canvas_uri
      json.set! :@type, 'sc:Canvas'
      json.label file_set.title.first
      json.width file_set.original_file&.width
      json.height file_set.original_file&.height
      json.images [file_set] do
        json.set! :@type, 'oa:Annotation'
        json.motivation 'sc:painting'
        json.resource do
          json.set! :@type, 'dctypes:Image'
          json.set! :@id, child_iiif_service.iiif_url
          json.width 640
          json.height 480
          json.service do
            if file_set.transcript_text.present?
              json.set! :@context, 'http://iiif.io/api/search/0/context.json'
              json.set! :@id, Rails.application.routes.url_helpers.solr_document_iiif_search_url(child_id)
              json.profile 'http://iiif.io/api/search/0/search'
              json.label 'Search within this item'
            else
              # The base url for the info.json file
              info_url = child_iiif_service.info_url

              json.set! :@context, 'http://iiif.io/api/image/2/context.json'
              json.set! :@id, info_url
              json.profile 'http://iiif.io/api/image/2/level2.json'
            end
          end
        end
        json.on canvas_uri
      end
    end
  end
end
