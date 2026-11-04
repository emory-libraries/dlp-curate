# frozen_string_literal: true

class CreateManifestJob < Hyrax::ApplicationJob
  def perform(work_id = nil)
    if work_id.present?
      process_work(work_id)
    else
      all_work_ids.each { |id| process_work(id) }
    end
  end

  private

    def process_work(work_id)
      solr_doc = ::SolrDocument.find(work_id)
      curation_concern = find_work(work_id)
      ManifestBuilderService.build_manifest(presenter: presenter(solr_doc), curation_concern:)
    end

    def find_work(work_id)
      if Hyrax.config.valkyrie_transition?
        Hyrax.query_service.find_by(id: work_id)
      else
        CurateGenericWork.find(work_id)
      end
    end

    def all_work_ids
      results = Hyrax::SolrService.query("has_model_ssim:CurateGenericWork", rows: 1_000_000, fl: "id")
      results.map { |doc| doc["id"] }
    end

    def presenter(document)
      ability = ManifestAbility.new
      Hyrax::CurateGenericWorkPresenter.new(document, ability)
    end
end
