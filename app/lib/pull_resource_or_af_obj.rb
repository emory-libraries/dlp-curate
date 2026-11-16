# frozen_string_literal: true

# This module will be used to define methods that will associate filesets with works
module PullResourceOrAfObj
  class IneligibleIdError < StandardError; end
  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  def pull_object_based_on_id(id:)
    if id.size == 14 && id.last(4) == '-cor'
      ActiveFedora::Base.find(id)
    elsif UUID_REGEX.match?(id)
      Hyrax.query_service.find_by(id:)
    else
      raise IneligibleIdError, "Provided ID #{id} doesn't match system requirements"
    end
  rescue Ldp::Gone
    raise IneligibleIdError, "An ActiveFedora object couldn't be found using ID: #{id}"
  rescue Valkyrie::Persistence::ObjectNotFoundError
    raise IneligibleIdError, "A Valkyrie object couldn't be found using ID: #{id}"
  end
end
