# frozen_string_literal: true

# Wings passes RDF::URI references for nested AF objects instead of Hashes,
# which Dry::Struct cannot coerce into PreservationEventResource.  This
# lenient type silently drops non-convertible values (RDF::URI, etc.) so the
# resource can still be loaded during the Valkyrie transition.
module SafePreservationEventType
  TYPE = Valkyrie::Types::Set.constructor do |value|
    Array.wrap(value).filter_map do |v|
      case v
      when ::PreservationEventResource then v
      when Hash                        then ::PreservationEventResource.new(v)
      end
    end
  end
end
