# frozen_string_literal: true

# Valkyrie resource for CurateGenericWork.
# Coexists alongside the AF CurateGenericWork during lazy migration.
class CurateGenericWorkResource < Hyrax::Work
  include Hyrax::Schema(:emory_basic_metadata)
  include Hyrax::Schema(:curate_generic_work_resource)
  include PreservationEvents
  Hyrax::ValkyrieLazyMigration.migrating(self, from: CurateGenericWork) if Hyrax.config.valkyrie_transition?

  attribute :preservation_event, SafePreservationEventType::TYPE

  def cleaned_member_ids
    member_ids&.compact&.map(&:to_s)&.uniq || []
  end

  def duplicated_or_nil_member_ids?
    member_ids.size != cleaned_member_ids.size
  end
end
