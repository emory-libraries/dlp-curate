# frozen_string_literal: true

require 'iiif_manifest'

# rubocop:disable Metrics/ClassLength
class ManifestBuilderService
  include IiifManifestCache

  def initialize(presenter: nil, curation_concern:)
    @presenter = presenter
    @curation_concern = curation_concern
  end

  # ManifestBuilderService.build_manifest(presenter, curation_concern)
  def self.build_manifest(presenter:, curation_concern:)
    service = ManifestBuilderService.new(presenter:, curation_concern:)
    service.manifest
  end

  def self.regenerate_manifest(presenter:, curation_concern:)
    service = ManifestBuilderService.new(presenter:, curation_concern:)
    service.regenerate_manifest_file
  end

  def manifest
    solr_doc = ::SolrDocument.find(@curation_concern.id)
    key = solr_doc[:manifest_cache_key_tesim]&.first.to_s + '_' + solr_doc[:id]

    if File.exist?(File.join(iiif_manifest_cache, key))
      render_manifest_file(key:)
    else
      placeholder_manifest = persist_placeholder_manifest(key)
      regenerate_manifest_file
      placeholder_manifest
    end
  end

  def regenerate_manifest_file
    solr_doc = ::SolrDocument.find(@curation_concern.id)
    key = solr_doc[:manifest_cache_key_tesim]&.first.to_s + '_' + solr_doc[:id]
    ManifestPersistenceJob.perform_later(key:,
                                         solr_doc:,
                                         root_url:           @presenter.manifest_url,
                                         manifest_metadata:  @presenter.manifest_metadata,
                                         curation_concern:   @curation_concern,
                                         sequence_rendering:)
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

    def render_manifest_file(key:)
      manifest_file = File.open(File.join(iiif_manifest_cache, key))
      manifest = manifest_file.read
      manifest_file.close
      manifest
    end

    def persist_placeholder_manifest(key)
      manifest_json = ApplicationController.render(
        template: 'manifest/placeholder',
        formats:  [:json],
        assigns:  {
          root_url: @presenter.manifest_url
        }
      )

      File.open(File.join(iiif_manifest_cache, key), 'w+') do |f|
        f.write(manifest_json)
      end
      manifest_json
    end

    def request_base_url
      "http://#{ENV['HOSTNAME'] || 'localhost:3000'}"
    end

    def preferred_file
      case @curation_concern
      when Hyrax::Resource
        preferred_valkyrie_file_metadata
      else
        @curation_concern.send(@curation_concern&.preferred_file)
      end
    end

    def preferred_file_id
      return @curation_concern.id.to_s unless preferred_file

      case preferred_file
      when Hyrax::FileMetadata
        preferred_file.id.to_s
      else
        preferred_file.id
      end
    end

    PREFERRED_USE_ORDER = [
      Hyrax::FileMetadata::Use::SERVICE_FILE,
      Hyrax::FileMetadata::Use::INTERMEDIATE_FILE,
      Hyrax::FileMetadata::Use::ORIGINAL_FILE
    ].freeze

    def preferred_valkyrie_file_metadata
      PREFERRED_USE_ORDER.each do |use|
        fm = Hyrax.custom_queries
                  .find_many_file_metadata_by_use(resource: @curation_concern, use:)
                  .first
        return fm if fm
      end
      nil
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
# rubocop:enable Metrics/ClassLength
