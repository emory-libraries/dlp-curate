# frozen_string_literal: true

class CreateManifestJob < Hyrax::ApplicationJob
  def perform(work_id = nil)
    if work_id.present?
      process_work(work_id)
    else
      CurateGenericWork.all.each do |work|
        process_work(work.id)
      end
    end
  end

  private

    def process_work(work_id)
      solr_doc = ::SolrDocument.find(work_id)
      ManifestBuilderService.build_manifest(presenter: presenter(solr_doc), curation_concern: CurateGenericWork.find(work_id))
    end

    # @param [SolrDocument] document
    def presenter(document)
      ability = ManifestAbility.new
      Hyrax::CurateGenericWorkPresenter.new(document, ability)
    end
end
