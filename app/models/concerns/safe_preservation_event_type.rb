# frozen_string_literal: true

# Wings passes RDF::URI references for nested AF objects instead of Hashes,
# which Dry::Struct cannot coerce into PreservationEventResource.  This
# lenient type silently drops non-convertible values (RDF::URI, etc.) so the
# resource can still be loaded during the Valkyrie transition.
module SafePreservationEventType
  MEMBER = Valkyrie::Types::Any.constructor do |value|
    case value
    when ::PreservationEventResource then value
    when Hash                        then ::PreservationEventResource.new(value)
    end
  end

  TYPE = Valkyrie::Types::Set.of(MEMBER).constructor(&:compact)
end
