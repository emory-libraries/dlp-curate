# frozen_string_literal: true

class TransferWorksJob < Hyrax::ApplicationJob
  def perform(import_col_id, true_col_id)
    StackProf.run(mode: :cpu, out: 'tmp/stackprof-curate.dump', raw: true, ignore_gc: true) do
      import_col = Collection.find(import_col_id)
      true_col = Collection.find(true_col_id)
      import_col.member_works.each do |work|
        work.member_of_collections << true_col unless true_col.member_work_ids.include?(work.id)
        work.member_of_collections.delete(import_col)
        work.save!
      end
    end
  end
end
