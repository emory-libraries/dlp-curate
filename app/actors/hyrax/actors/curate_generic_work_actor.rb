# Generated via
#  `rails generate hyrax:work CurateGenericWork`
module Hyrax
  module Actors
    class CurateGenericWorkActor < Hyrax::Actors::BaseActor
      include PreservationEvents
      KNOWN_NESTED_ATTRIBUTES = [:preservation_workflow_attributes].freeze
      # Some CSV rows have blank metadata and are only used to attach a file.
      # Those rows should come through with env.attributes["skip_metadata"] = true
      # 1. Remove that value from the attributes, since it will cause an error if you try to save it to the object
      # 2. If skip_metadata == true, do not apply the metadata to the object, but do all other expected update behavior
      def apply_save_data_to_curation_concern(env)
        skip_metadata = env.attributes["skip_metadata"]
        env.attributes.delete(:skip_metadata)
        env.curation_concern.attributes = clean_attributes(env.attributes) unless skip_metadata
        env.curation_concern.date_modified = TimeService.time_in_utc

        super
        # ActiveFedora fails to propgate changes to nested attributes to
        # `#resource` when indexed nested attributes are used. We force the
        # issue here to work around for form edits.
        (env.attributes.keys && KNOWN_NESTED_ATTRIBUTES).each do |attribute_key|
          attribute = attribute_key.to_s.gsub('_attributes', '').to_sym
          env.curation_concern.send(attribute).each { |member| member.try(:persist!) }
        end
      end

      def create(env)
        event_start = DateTime.current # record event_start timestamp
        apply_creation_data_to_curation_concern(env)
        apply_save_data_to_curation_concern(env)
        # Create our three required events
        work_creation = { 'type' => 'Object Validation (Work created)', 'start' => event_start, 'outcome' => 'Success', 'details' => 'Valid submission package submitted',
                          'software_version' => 'Curate v.1', 'user' => env.user.uid }
        work_policy = { 'type' => 'Policy Assignment', 'start' => event_start, 'outcome' => 'Success', 'details' => 'Policy was assigned', 'software_version' => 'Curate v.1',
                        'user' => env.user.uid }
        work_metadata = { 'type' => 'Metadata Extraction', 'start' => event_start, 'outcome' => 'Success', 'details' => 'Descriptive, Rights, and Administrative metadata extracted from CSV',
                          'software_version' => 'Curate v.1', 'user' => env.user.uid }
        save(env) && next_actor.create(env) && run_callbacks(:after_create_concern, env)
        # Create preservation events
        create_preservation_event(env.curation_concern, work_creation)
        create_preservation_event(env.curation_concern, work_policy)
        create_preservation_event(env.curation_concern, work_metadata)
      end
    end
  end
end
