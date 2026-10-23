# frozen_string_literal: true

class ReindexObjectJob < Hyrax::ApplicationJob
  def perform(id)
    if Hyrax.config.valkyrie_transition?
      resource = Hyrax.query_service.find_by(id:)
      Hyrax.index_adapter.save(resource:)
    else
      ActiveFedora::Base.find(id).update_index
    end
  end
end
