# frozen_string_literal: true

# This module will be used to define preservation_event
# methods for work and fileset
module PreservationEvents
  # @param object - work or file_set object
  # @param event - hash with all event requirements (details, start, type, user, outcome, software_version)
  def create_preservation_event(object, event)
    object.preservation_event_attributes = [{ event_details:    event['details'],
                                              event_end:        event['end'] || DateTime.current,
                                              event_start:      event['start'],
                                              event_type:       event['type'],
                                              initiating_user:  event['user'],
                                              outcome:          event['outcome'],
                                              software_version: event['software_version'] }]
    object.save! if object.errors.empty? # save object only if there aren't any errors, eg: validation errors
  end

  def check_for_preexisting_preservation_events(file_set, sha1, event_start)
    matching_preservation_events = file_set.preservation_event.select do |e|
      e.event_type == ['Fixity Check'] && e.event_start == [DateTime.parse(event_start)]
    end

    matching_preservation_events.select { |mpe| mpe.event_details.first.include? sha1 }.present?
  end
end
