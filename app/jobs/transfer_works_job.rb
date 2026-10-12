# frozen_string_literal: true
require 'stackprof'

class TransferWorksJob < Hyrax::ApplicationJob
  def perform(import_col_id, true_col_id)
    ::StackProf.run(mode: :cpu, out: 'tmp/stackprof-curate.dump', raw: true, ignore_gc: true) do
      if Hyrax.config.valkyrie_transition?
        transfer_valkyrie(import_col_id, true_col_id)
      else
        transfer_af(import_col_id, true_col_id)
      end
    end
  end

  private

    def transfer_af(import_col_id, true_col_id)
      import_col = Collection.find(import_col_id)
      true_col = Collection.find(true_col_id)
      import_col.member_works.each do |work|
        work.member_of_collections << true_col unless true_col.member_work_ids.include?(work.id)
        work.member_of_collections.delete(import_col)
        work.save!
      end
    end

    def transfer_valkyrie(import_col_id, true_col_id)
      work_docs = Hyrax::SolrService.query(
        "member_of_collection_ids_ssim:#{import_col_id} AND has_model_ssim:CurateGenericWork",
        rows: 1_000_000, fl: "id"
      )

      work_docs.each do |doc|
        transfer_valkyrie_work(doc["id"], import_col_id, true_col_id)
      end
    end

    def transfer_valkyrie_work(work_id, import_col_id, true_col_id)
      work = Hyrax.query_service.find_by(id: work_id)
      col_ids = Array(work.member_of_collection_ids).map { |cid| Valkyrie::ID.new(cid.to_s) }
      true_col_valkyrie_id = Valkyrie::ID.new(true_col_id)
      col_ids << true_col_valkyrie_id unless col_ids.any? { |cid| cid.to_s == true_col_id }
      col_ids.reject! { |cid| cid.to_s == import_col_id }
      work.member_of_collection_ids = col_ids
      Hyrax.persister.save(resource: work)
      Hyrax.index_adapter.save(resource: work)
    end
end
