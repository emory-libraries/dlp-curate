# frozen_string_literal: true

require 'iiif_manifest'

class ManifestBuilderService
  include IiifManifestCache

  def initialize(presenter: nil, curation_concern:)
    @presenter = presenter
    @curation_concern = curation_concern
  end

  def manifest
    manifest_builder
  end

  # ManifestBuilderService.build_manifest(presenter, curation_concern)
  def self.build_manifest(presenter:, curation_concern:)
    service = ManifestBuilderService.new(presenter: presenter, curation_concern: curation_concern)
    service.manifest
  end

  def iiif_url
    Hyrax.config.iiif_image_url_builder.call(
      preferred_file_id,
      request_base_url,
      Hyrax.config.iiif_image_size_default
    )
  end

  def info_url
    Hyrax.config.iiif_info_url_builder.call(
      preferred_file_id,
      request_base_url
    )
  end

  private

    def manifest_builder
      solr_doc = ::SolrDocument.find(@curation_concern.id)
      key = solr_doc[:manifest_cache_key_tesim]&.first.to_s + '_' + solr_doc[:id]

      if File.exist?(File.join(iiif_manifest_cache, key))
        render_manifest_file(key: key)
      else
        ManifestPersistenceJob.perform_later(key: key, solr_doc: solr_doc, root_url: @presenter.manifest_url, manifest_metadata: @presenter.manifest_metadata,
                                             curation_concern: @curation_concern, sequence_rendering: sequence_rendering)
        ApplicationController.render(template: 'manifest/placeholder.json', assigns: { root_url: @presenter.manifest_url })
      end
    end

    def render_manifest_file(key:)
      manifest_file = File.open(File.join(iiif_manifest_cache, key))
      manifest = manifest_file.read
      manifest_file.close
      manifest
    end

    def request_base_url
      "http://#{ENV['HOSTNAME'] || 'localhost:3000'}"
    end

    def preferred_file
      @curation_concern.send(@curation_concern&.preferred_file)
    end

    def preferred_file_id
      if preferred_file
        preferred_file.id
      else
        @curation_concern.id
      end
    end

    #
    # @return [Array] array of rendering hashes
    def sequence_rendering
      renderings = []
      solr_doc = ::SolrDocument.find(@curation_concern.id)
      if solr_doc.rendering_ids.present?
        solr_doc.rendering_ids.each do |file_set_id|
          renderings << @presenter.manifest_helper.build_rendering(file_set_id)
        end
      end
      renderings.flatten
    end
end
