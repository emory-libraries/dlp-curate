# Generated via
#  `rails generate hyrax:work CurateGenericWork`
module Hyrax
  module Actors
    class CurateGenericWorkActor < Hyrax::Actors::BaseActor
      KNOWN_NESTED_ATTRIBUTES = [:preservation_workflow_attributes].freeze
      def apply_save_data_to_curation_concern(env)
        super
        # ActiveFedora fails to propgate changes to nested attributes to
        # `#resource` when indexed nested attributes are used. We force the
        # issue here to work around for form edits.
        (env.attributes.keys && KNOWN_NESTED_ATTRIBUTES).each do |attribute_key|
          attribute = attribute_key.to_s.gsub('_attributes', '').to_sym
          env.curation_concern.send(attribute).each { |member| member.try(:persist!) }
        end
      end
    end
  end
end
