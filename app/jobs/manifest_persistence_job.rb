# frozen_string_literal: true

class ManifestPersistenceJob < Hyrax::ApplicationJob
  include IiifManifestCache

  def perform(key:, solr_doc:, root_url:, manifest_metadata:, curation_concern:, sequence_rendering:)
    manifest_json = ApplicationController.render(
      template: 'manifest/manifest.json',
      assigns:  {
        solr_doc:           solr_doc,
        root_url:           root_url,
        manifest_metadata:  manifest_metadata,
        manifest_rendering: sequence_rendering,
        image_concerns:     image_concerns(curation_concern)
      }
    )
    remove_outdated_manifests(solr_doc[:id])
    persist_manifest(key: key, manifest_json: manifest_json)
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
      file_set_ids = (curation_concern.ordered_member_ids - curation_concern.child_work_ids)&.compact
      if file_set_ids.empty?
        []
      else
        file_set_ids
      end
    end
end
