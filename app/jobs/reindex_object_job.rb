# frozen_string_literal: true

class ReindexObjectJob < Hyrax::ApplicationJob
  def perform(id)
    ActiveFedora::Base.find(id).update_index
  end
end
