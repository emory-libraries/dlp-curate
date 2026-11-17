# frozen_string_literal: true

# Wings passes RDF::URI references for nested AF objects instead of Hashes,
# which Dry::Struct cannot coerce into PreservationWorkflowResource. This
# lenient type drops those values so the resource can still be loaded; the
# Frigg persister copies the AF workflows over when the work is migrated.
module SafePreservationWorkflowType
  TYPE = Valkyrie::Types::Set.constructor do |value|
    Array.wrap(value).filter_map do |v|
      case v
      when ::PreservationWorkflowResource then v
      when Hash                           then ::PreservationWorkflowResource.new(v)
      end
    end
  end
end
