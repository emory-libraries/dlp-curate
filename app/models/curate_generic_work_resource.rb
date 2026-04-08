# frozen_string_literal: true

# Valkyrie resource for CurateGenericWork.
# Coexists alongside the AF CurateGenericWork during lazy migration.
class CurateGenericWorkResource < Hyrax::Work
  include Hyrax::Schema(:emory_basic_metadata)
  include Hyrax::Schema(:curate_generic_work_resource)
  include PreservationEvents

  attribute :preservation_event, Valkyrie::Types::Set.of(::PreservationEventResource)
end
