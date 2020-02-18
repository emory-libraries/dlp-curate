# frozen_string_literal: true

require 'iiif_manifest'

class ManifestBuilderService
  def initialize(identifier)
    @identifier = identifier
  end

  def manifest
    manifest_builder
  end

  # ManifestBuilderService.build_manifest(identifier)
  def self.build_manifest(identifier)
    service = ManifestBuilderService.new(identifier)
    service.manifest
  end

  private

    def manifest_builder
      solr_doc = ::SolrDocument.find(@identifier)
      date_modified = solr_doc[:date_modified_dtsi] || solr_doc[:system_create_dtsi]
      key = date_modified.to_datetime.strftime('%Y-%m-%d_%H-%M-%S') + '_' + solr_doc[:id]

      if File.exist?(Rails.root.join('tmp', key))
        render_manifest_file(key: key)
      else
        manifest_hash = ::IIIFManifest::ManifestFactory.new(presenter(solr_doc)).to_h
        persist_manifest(key: key, manifest_hash: manifest_hash)
        manifest_hash.to_json
      end
    end

    # @param [SolrDocument] document
    def presenter(document)
      ability = Ability.new(::User.new)
      Hyrax::CurateGenericWorkPresenter.new(document, ability)
    end

    def render_manifest_file(key:)
      manifest_file = File.open(Rails.root.join('tmp', key))
      manifest = manifest_file.read
      manifest_file.close
      manifest
    end

    def persist_manifest(key:, manifest_hash:)
      File.open(Rails.root.join('tmp', key), 'w+') do |f|
        f.write(manifest_hash.to_json)
      end
    end
end
