# frozen_string_literal: true

class ReindexObjectJob < Hyrax::ApplicationJob
  include PullResourceOrAfObj
  discard_on IneligibleIdError

  def perform(id)
    obj = pull_object_based_on_id(id:)
    case obj
    when Hyrax::Resource
      Hyrax.index_adapter.save(resource:)
    else
      pulled_af_obj.update_index
    end
  end
end
