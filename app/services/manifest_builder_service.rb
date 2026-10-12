# frozen_string_literal: true

require 'iiif_manifest'

# rubocop:disable Metrics/ClassLength
class ManifestBuilderService
  include IiifManifestCache

  # How long a queued ManifestPersistenceJob suppresses re-queueing. After this,
  # a request for a still-missing manifest queues a new job, so a failed or lost
  # job cannot leave a work showing the placeholder indefinitely.
  PENDING_REGENERATION_TTL = 10.minutes

  # Present only in the placeholder template; used to recognise placeholder
  # files cached by earlier versions of this service.
  PLACEHOLDER_CANVAS_ID_SUFFIX = '/canvas/placeholder"'

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

  # Returns the cached manifest, or a placeholder while a ManifestPersistenceJob
  # builds it. The placeholder is never written to the cache.
  def manifest
    solr_doc = ::SolrDocument.find(@curation_concern.id)
    key = solr_doc[:manifest_cache_key_tesim]&.first.to_s + '_' + solr_doc[:id]

    cached_manifest = render_manifest_file(key:) if File.exist?(manifest_cache_path(key))
    return cached_manifest if cached_manifest && !placeholder?(cached_manifest)

    queue_regeneration(key)
    render_placeholder_manifest
  end

  def regenerate_manifest_file
    solr_doc = ::SolrDocument.find(@curation_concern.id)
    key = solr_doc[:manifest_cache_key_tesim]&.first.to_s + '_' + solr_doc[:id]
    ManifestPersistenceJob.perform_later(key:,
                                         solr_doc:,
                                         root_url:            @presenter.manifest_url,
                                         manifest_metadata:   @presenter.manifest_metadata,
                                         curation_concern_id: @curation_concern.id.to_s,
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
      manifest_file = File.open(manifest_cache_path(key))
      manifest = manifest_file.read
      manifest_file.close
      manifest
    end

    def placeholder?(manifest_json)
      manifest_json.include?(PLACEHOLDER_CANVAS_ID_SUFFIX)
    end

    # Queues a ManifestPersistenceJob unless one was queued for this key within
    # PENDING_REGENERATION_TTL. The marker is removed by the job once the
    # manifest is persisted, or here if queueing fails.
    def queue_regeneration(key)
      marker = pending_manifest_marker_path(key)
      return if File.exist?(marker) && File.mtime(marker) > PENDING_REGENERATION_TTL.ago

      FileUtils.touch(marker)
      begin
        regenerate_manifest_file
      rescue StandardError
        FileUtils.rm_f(marker)
        raise
      end
    end

    def render_placeholder_manifest
      ApplicationController.render(
        template: 'manifest/placeholder',
        formats:  [:json],
        assigns:  {
          root_url: @presenter.manifest_url
        }
      )
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
      rescue StandardError => e
        Rails.logger.debug { "[ManifestBuilderService] Error finding file metadata for use #{use}: #{e.class}" }
        next
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
