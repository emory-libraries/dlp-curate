# frozen_string_literal: true

module IiifManifestCache
  # Marker file written next to a manifest's cache path while a
  # ManifestPersistenceJob is queued for it.
  PENDING_MANIFEST_SUFFIX = '.pending'

  def iiif_manifest_cache
    ENV['IIIF_MANIFEST_CACHE'] || Rails.root.join("tmp").to_s
  end

  def manifest_cache_path(key)
    File.join(iiif_manifest_cache, key)
  end

  def pending_manifest_marker_path(key)
    manifest_cache_path(key) + PENDING_MANIFEST_SUFFIX
  end
end
