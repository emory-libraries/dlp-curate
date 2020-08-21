# frozen_string_literal: true

json.set! :@context, 'http://iiif.io/api/presentation/2/context.json'
json.set! :@type, 'sc:Manifest'
json.set! :@id, @root_url
json.label "Content is being assembled - please return soon"

json.sequences [''] do
  json.set! :@type, 'sc:Sequence'
  json.set! :@id, "#{@root_url}/sequence/normal"
  json.canvases [''] do
    canvas_uri = "#{@root_url}/canvas/placeholder"
    json.set! :@id, canvas_uri
    json.set! :@type, 'sc:Canvas'
  end
end
