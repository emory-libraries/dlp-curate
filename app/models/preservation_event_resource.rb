# frozen_string_literal: true

class PreservationEventResource < Valkyrie::Resource
  include Hyrax::Schema(:preservation_event_metadata)

  def preservation_event_terms
    attributes_map = { 'event_details' => event_details,
                       'event_end' => event_end,
                       'event_start' => event_start,
                       'event_type' => event_type,
                       'initiating_user' => initiating_user,
                       'outcome' => outcome,
                       'software_version' => software_version }
    attributes_map.to_json
  end

  def failed_event_json
    { "event_details" => event_details, "event_start" => event_start }.to_json
  end
end
