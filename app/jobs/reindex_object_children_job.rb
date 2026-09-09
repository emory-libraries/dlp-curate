# frozen_string_literal: true

class ReindexObjectChildrenJob < Hyrax::ApplicationJob
  def perform(id)
    if Hyrax.config.valkyrie_transition?
      reindex_children_valkyrie(id)
    else
      reindex_children_af(id)
    end
  end

  private

    def reindex_children_af(id)
      obj = ActiveFedora::Base.find(id)
      children_ids = obj.try(:member_ids)
      return if children_ids.blank?

      children = children_ids.compact.map { |child_id| ActiveFedora::Base.find(child_id) }
      children.each(&:update_index)
      Rails.logger.info "Objects reindexed: #{children}"
    end

    def reindex_children_valkyrie(id)
      parent = Hyrax.query_service.find_by(id:)
      children_ids = parent.try(:member_ids)
      return if children_ids.blank?

      children_ids.compact.each do |child_id|
        child = Hyrax.query_service.find_by(id: child_id)
        Hyrax.index_adapter.save(resource: child)
      end
      Rails.logger.info "Objects reindexed for parent #{id}: #{children_ids.length} children"
    end
end
