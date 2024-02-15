# frozen_string_literal: true

class ReplaceWorkMembersJob < Hyrax::ApplicationJob
  def perform(work, cleaned_member_ids)
    file_sets = cleaned_member_ids.map { |id| FileSet.find(id) }

    work.ordered_members = file_sets
    work.save
    regen_manifest(work)
  end

  def regen_manifest(work)
    solr_doc = SolrDocument.find(work.id)
    ability = ManifestAbility.new
    presenter = Hyrax::CurateGenericWorkPresenter.new(solr_doc, ability)

    ManifestBuilderService.regenerate_manifest(presenter: presenter, curation_concern: work)
  end
end
