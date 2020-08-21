# frozen_string_literal: true
class PlaceholderManifestOutput
  def manifest_output(work)
    {
      "@context":  "http://iiif.io/api/presentation/2/context.json",
      "@type":     "sc:Manifest",
      "@id":       "http://example.com/iiif/#{work.id}/manifest",
      "label":     "Content is being assembled - please return soon",
      "sequences": [
        {
          "@type":    "sc:Sequence",
          "@id":      "http://example.com/iiif/#{work.id}/manifest/sequence/normal",
          "canvases": [
            {
              "@id":   "http://example.com/iiif/#{work.id}/manifest/canvas/placeholder",
              "@type": "sc:Canvas"
            }
          ]
        }
      ]
    }
  end
end
