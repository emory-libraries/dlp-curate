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
      date_modified = solr_doc[:date_modified_dtsi] || solr_doc[:system_create_dtsi]
      key = date_modified.to_datetime.strftime('%Y-%m-%d_%H-%M-%S') + '_' + solr_doc[:id]

      if File.exist?(File.join(iiif_manifest_cache, key))
        render_manifest_file(key: key)
      else
        manifest_json = ApplicationController.render(template: 'manifest/manifest.json', assigns: { solr_doc:          solr_doc,
                                                                                                    root_url:          @presenter.manifest_url,
                                                                                                    manifest_metadata: @presenter.manifest_metadata,
                                                                                                    image_concerns:    image_concerns })
        persist_manifest(key: key, manifest_json: manifest_json)
        manifest_json
      end
    end

    def render_manifest_file(key:)
      manifest_file = File.open(File.join(iiif_manifest_cache, key))
      manifest = manifest_file.read
      manifest_file.close
      manifest
    end

    def persist_manifest(key:, manifest_json:)
      File.open(File.join(iiif_manifest_cache, key), 'w+') do |f|
        f.write(manifest_json)
      end
    end

    def image_concerns
      file_set_ids = @curation_concern.ordered_member_ids - @curation_concern.child_work_ids
      if file_set_ids.empty?
        []
      else
        file_set_ids
      end
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
end
