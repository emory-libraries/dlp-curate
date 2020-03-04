# frozen_string_literal: true

module IiifManifestCache
  def iiif_manifest_cache
    ENV['IIIF_MANIFEST_CACHE'] || Rails.root.join("tmp").to_s
  end
end
