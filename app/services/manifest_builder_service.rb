# frozen_string_literal: true

require 'iiif_manifest'

class ManifestBuilderService
  def initialize(identifier, presenter)
    @identifier = identifier
    @presenter = presenter
  end

  def manifest
    manifest_builder
  end

  # ManifestBuilderService.build_manifest(identifier)
  def self.build_manifest(identifier, presenter)
    service = ManifestBuilderService.new(identifier, presenter)
    service.manifest
  end

  private

    def manifest_builder
      solr_doc = ::SolrDocument.find(@identifier)
      date_modified = solr_doc[:date_modified_dtsi] || solr_doc[:system_create_dtsi]
      key = date_modified.to_datetime.strftime('%Y-%m-%d_%H-%M-%S') + '_' + solr_doc[:id]

      if File.exist?(File.join(ENV['IIIF_MANIFEST_CACHE'], key))
        render_manifest_file(key: key)
      else
        manifest_hash = ::IIIFManifest::ManifestFactory.new(@presenter).to_h
        persist_manifest(key: key, manifest_hash: manifest_hash)
        manifest_hash.to_json
      end
    end

    def render_manifest_file(key:)
      manifest_file = File.open(File.join(ENV['IIIF_MANIFEST_CACHE'], key))
      manifest = manifest_file.read
      manifest_file.close
      manifest
    end

    def persist_manifest(key:, manifest_hash:)
      File.open(File.join(ENV['IIIF_MANIFEST_CACHE'], key), 'w+') do |f|
        f.write(manifest_hash.to_json)
      end
    end
end
