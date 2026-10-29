# frozen_string_literal: true

class ReindexObjectJob < Hyrax::ApplicationJob
  class IneligibleIdError < StandardError; end
  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
  discard_on IneligibleIdError

  def perform(id)
    if id.size == 14 && id.last(4) == '-cor'
      pulled_af_obj = ActiveFedora::Base.find(id)
      pulled_af_obj.update_index
    elsif UUID_REGEX.match?(id)
      resource = Hyrax.query_service.find_by(id:)
      Hyrax.index_adapter.save(resource:)
    else
      raise IneligibleIdError, "Provided ID #{id} doesn't match system requirements"
    end
  rescue Ldp::Gone
    raise IneligibleIdError, "An ActiveFedora object couldn't be found using ID: #{id}"
  rescue Valkyrie::Persistence::ObjectNotFoundError
    raise IneligibleIdError, "A Valkyrie object couldn't be found using ID: #{id}"
  end
end
