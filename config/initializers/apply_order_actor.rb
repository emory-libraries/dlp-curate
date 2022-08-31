# frozen_string_literal: true

Hyrax::Actors::ApplyOrderActor.class_eval do
  # @todo Why is this not doing work.save?
  # @see Hyrax::Actors::AddToWorkActor for duplication
  def cleanup_ids_to_remove_from_curation_concern(curation_concern, ordered_member_ids)
    (curation_concern.ordered_member_ids - ordered_member_ids)&.compact&.each do |old_id|
      work = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: old_id, use_valkyrie: false)
      curation_concern.ordered_members.delete(work)
      curation_concern.members.delete(work)
    end
  end

  def add_new_work_ids_not_already_in_curation_concern(env, ordered_member_ids)
    (ordered_member_ids - env.curation_concern.ordered_member_ids)&.compact&.each do |work_id|
      work = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: work_id, use_valkyrie: false)
      if can_edit_both_works?(env, work)
        env.curation_concern.ordered_members << work
        env.curation_concern.save!
      else
        env.curation_concern.errors[:ordered_member_ids] << "Works can only be related to each other if user has ability to edit both."
      end
    end
  end
end
