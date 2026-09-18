# frozen_string_literal: true

class ManifestPersistenceJob < Hyrax::ApplicationJob
  include IiifManifestCache

  # Retry on template errors (e.g., Fedora connectivity, Wings wrapping
  # failures) and LDP errors (e.g., Fedora 4/6 transient issues).
  retry_on ActionView::Template::Error, Ldp::HttpError, Ldp::BadRequest,
           wait: :polynomially_longer, attempts: 5 do |job, error|
    Rails.logger.error(
      "[ManifestPersistenceJob] Failed after all retries for " \
      "curation_concern_id=#{job.arguments.first[:curation_concern_id]}: " \
      "#{error.class} — #{error.message}"
    )
  end

  def perform(key:, solr_doc:, root_url:, manifest_metadata:, sequence_rendering:,
              curation_concern_id: nil, curation_concern: nil)
    concern = curation_concern || load_curation_concern(curation_concern_id)
    manifest_json = ApplicationController.render(
      template: 'manifest/manifest',
      formats:  [:json],
      assigns:  {
        solr_doc:,
        root_url:,
        manifest_metadata:,
        manifest_rendering: sequence_rendering,
        image_concerns:     image_concerns(concern)
      }
    )

    remove_outdated_manifests(solr_doc[:id])
    persist_manifest(key:, manifest_json:)
  end

  private

    def load_curation_concern(id)
      if Hyrax.config.valkyrie_transition?
        begin
          Hyrax.query_service.find_by(id:)
        rescue Valkyrie::Persistence::ObjectNotFoundError, Ldp::HttpError, Faraday::Error => e
          Rails.logger.warn("[ManifestPersistenceJob] Valkyrie query failed for #{id}, falling back to AF: #{e.class}")
          CurateGenericWork.find(id)
        end
      else
        CurateGenericWork.find(id)
      end
    end

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
        ids = valkyrie_file_set_ids(curation_concern)
        return ids if ids.present?

        # Valkyrie find_members returned empty — Wings may not have populated
        # member_ids from AF ordered_members. Fall back to direct AF lookup.
        af_file_set_ids_from_solr_or_af(curation_concern)
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
      Hyrax.query_service
           .find_members(resource: curation_concern)
           .select(&:file_set?)
           .map { |fs| fs.id.to_s }
    rescue StandardError => e
      Rails.logger.warn("[ManifestPersistenceJob] find_members failed for #{curation_concern.id}: #{e.class}")
      []
    end

    # Last-resort fallback: try loading the AF work directly to get
    # ordered_member_ids when Valkyrie find_members returns empty.
    def af_file_set_ids_from_solr_or_af(curation_concern)
      af_work = CurateGenericWork.find(curation_concern.id.to_s)
      ids = af_work.ordered_member_ids
      log_nil_members(af_work) if ids.any?(nil)
      ids.compact - af_work.child_work_ids
    rescue ActiveFedora::ObjectNotFoundError, StandardError => e
      Rails.logger.warn("[ManifestPersistenceJob] AF fallback for members also failed for #{curation_concern.id}: #{e.class}")
      []
    end

    def log_nil_members(curation_concern)
      Rails.logger.error "The CurateGenericWork with the id #{curation_concern.id} contains nil objects in its ordered_members."
    end
end
