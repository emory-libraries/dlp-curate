# frozen_string_literal: true

class ManifestPersistenceJob < Hyrax::ApplicationJob
  include IiifManifestCache

  retry_on(ActionView::Template::Error) do |_job, error|
    Rails.logger.error(error.message)
  end

  def perform(key:, solr_doc:, root_url:, manifest_metadata:, curation_concern:, sequence_rendering:)
    manifest_json = ApplicationController.render(
      template: 'manifest/manifest',
      formats:  [:json],
      assigns:  {
        solr_doc:,
        root_url:,
        manifest_metadata:,
        manifest_rendering: sequence_rendering,
        image_concerns:     image_concerns(curation_concern)
      }
    )

    remove_outdated_manifests(solr_doc[:id])
    persist_manifest(key:, manifest_json:)
  end

  private

    def persist_manifest(key:, manifest_json:)
      File.open(File.join(iiif_manifest_cache, key), 'w+') do |f|
        f.write(manifest_json)
      end
    end

    def remove_outdated_manifests(solr_doc_id)
      outdated_manifests = Dir.glob(iiif_manifest_cache + '/*').select do |path|
        path.ends_with?("_#{solr_doc_id}")
      end

      outdated_manifests.each { |path| File.delete(path) if File.exist?(path) }
    end

    def image_concerns(curation_concern)
      file_set_ids = file_set_member_ids(curation_concern).compact
      file_set_ids.presence || []
    end

    def file_set_member_ids(curation_concern)
      case curation_concern
      when Hyrax::Resource
        valkyrie_file_set_ids(curation_concern)
      else
        af_file_set_ids(curation_concern)
      end
    end

    def af_file_set_ids(curation_concern)
      ids = curation_concern.ordered_member_ids
      log_nil_members(curation_concern) if ids.any?(nil)
      ids - curation_concern.child_work_ids
    end

    def valkyrie_file_set_ids(curation_concern)
      Hyrax.custom_queries
           .find_child_file_sets(resource: curation_concern)
           .map { |fs| fs.id.to_s }
    end

    def log_nil_members(curation_concern)
      Rails.logger.error "The CurateGenericWork with the id #{curation_concern.id} contains nil objects in its ordered_members."
    end
end
