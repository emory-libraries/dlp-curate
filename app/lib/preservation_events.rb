# frozen_string_literal: true

# This module will be used to define preservation_event
# methods for work and fileset
module PreservationEvents
  # @param object - work or file_set object
  # @param event_type - preservation_event type
  # @param event_start - start time for event
  # @param event_details - details of the preservation_event
  # @param software_version - software_version used if any
  def create_preservation_event(object, event_type, event_start, outcome, event_details = nil, software_version = nil, user = nil)
    object.preservation_event_attributes = [{ event_details:    event_details,
                                              event_end:        DateTime.current,
                                              event_start:      event_start,
                                              event_type:       event_type,
                                              initiating_user:  user,
                                              outcome:          outcome,
                                              software_version: software_version }]
    object.save!
  end
end
