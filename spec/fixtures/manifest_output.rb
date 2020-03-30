# frozen_string_literal: true
class ManifestOutput
  def manifest_output(work, file_set)
    {
      "@context":  "http://iiif.io/api/presentation/2/context.json",
      "@type":     "sc:Manifest",
      "@id":       "http://example.com/iiif/#{work.id}/manifest",
      "label":     "Test title",
      "metadata":  [],
      "sequences": [
        {
          "@type":    "sc:Sequence",
          "@id":      "http://example.com/iiif/#{work.id}/manifest/sequence/normal",
          "canvases": [
            {
              "@id":    "http://example.com/iiif/#{work.id}/manifest/canvas/#{file_set.id}",
              "@type":  "sc:Canvas",
              "label":  file_set.title.first,
              "width":  file_set.original_file.width,
              "height": file_set.original_file.height,
              "images": [
                {
                  "@type":      "oa:Annotation",
                  "motivation": "sc:painting",
                  "resource":   {
                    "@type":   "dctypes:Image",
                    "@id":     "example.com/iiif/2/#{file_set.service_file.checksum.uri.to_s.gsub('urn:sha1:', '')}/full/600,/0/default.jpg",
                    "width":   640,
                    "height":  480,
                    "service": {
                      "@context": "http://iiif.io/api/image/2/context.json",
                      "@id":      "example.com/iiif/2/#{file_set.service_file.checksum.uri.to_s.gsub('urn:sha1:', '')}",
                      "profile":  "http://iiif.io/api/image/2/level2.json"
                    }
                  },
                  "on":         "http://example.com/iiif/#{work.id}/manifest/canvas/608hdr7qrt-cor"
                }
              ]
            }
          ]
        }
      ]
    }
  end
end
