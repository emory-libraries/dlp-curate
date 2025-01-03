# frozen_string_literal: true

class ReindexObjectChildrenJob < Hyrax::ApplicationJob
  def perform(id)
    @id = id

    object_children.each(&:update_index)
    Rails.logger.info "Objects reindexed: #{object_children}"
  end

  def object_children
    obj = ActiveFedora::Base.find(@id)
    obj_children_ids = obj.try(:member_ids)

    obj_children_ids.present? ? pull_child_objects(obj_children_ids) : []
  end

  def pull_child_objects(child_ids)
    child_ids.compact.map { |child_id| ActiveFedora::Base.find(child_id) }
  end
end
