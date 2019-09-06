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
      # Some CSV rows have blank metadata and are only used to attach a file.
      # Those rows should come through with env.attributes["skip_metadata"] = true
      # 1. Remove that value from the attributes, since it will cause an error if you try to save it to the object
      # 2. If skip_metadata == true, do not apply the metadata to the object, but do all other expected update behavior
      def apply_save_data_to_curation_concern(env)
        skip_metadata = env.attributes["skip_metadata"]
        env.attributes.delete(:skip_metadata)
        env.curation_concern.attributes = clean_attributes(env.attributes) unless skip_metadata
        env.curation_concern.date_modified = TimeService.time_in_utc
      end
    end
  end
end
