# frozen_string_literal: true

class ReplaceWorkMembersJob < Hyrax::ApplicationJob
  def perform(work, cleaned_member_ids)
    case work
    when Hyrax::Resource
      replace_valkyrie_members(work, cleaned_member_ids)
    else
      replace_af_members(work, cleaned_member_ids)
    end
    regen_manifest(work)
  end

  private

    def replace_af_members(work, cleaned_member_ids)
      file_sets = cleaned_member_ids.map { |id| FileSet.find(id) }
      work.ordered_members = file_sets
      work.save
    end

    def replace_valkyrie_members(work, cleaned_member_ids)
      work.member_ids = cleaned_member_ids.map { |id| Valkyrie::ID.new(id) }
      Hyrax.persister.save(resource: work)
      Hyrax.index_adapter.save(resource: work)
    end

    def regen_manifest(work)
      solr_doc = SolrDocument.find(work.id)
      ability = ManifestAbility.new
      presenter = Hyrax::CurateGenericWorkPresenter.new(solr_doc, ability)
      ManifestBuilderService.regenerate_manifest(presenter:, curation_concern: work)
    end
end
