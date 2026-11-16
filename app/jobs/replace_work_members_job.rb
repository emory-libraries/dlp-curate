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
      file_sets = pull_actual_file_set_objs(cleaned_member_ids)
      file_sets.each { |fs| Hyrax.index_adapter.save(resource: fs) }

      work.member_ids = file_sets.map { |fs| fs.id.to_s }
      persisted_work = Hyrax.persister.save(resource: work)
      Hyrax.index_adapter.save(resource: persisted_work)
    end

    def regen_manifest(work)
      solr_doc = SolrDocument.find(work.id)
      ability = ManifestAbility.new
      presenter = Hyrax::CurateGenericWorkPresenter.new(solr_doc, ability)
      ManifestBuilderService.regenerate_manifest(presenter:, curation_concern: work)
    end

    def pull_actual_file_set_objs(file_set_ids)
      file_set_ids.map do |fsid|
        Hyrax.query_service.find_by(id: fsid)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end.compact
    end
end
