# frozen_string_literal: true

# This module will be used to define preservation_event methods for work and fileset.
module PreservationEvents
  # @param object - work or file_set object
  # @param event - hash with all event requirements (details, start, type, user, outcome, software_version)
  def create_preservation_event(object, event)
    case object
    when ActiveFedora::Base
      active_fedora_create(object, event)
    else
      valkyrie_create(object, event)
    end
  end

  def check_for_preexisting_preservation_events(file_set, sha1, event_start)
    matching_preservation_events = file_set.preservation_event.select do |e|
      e.event_type == ['Fixity Check'] && e.event_start == [DateTime.parse(event_start)]
    end

    matching_preservation_events.select { |mpe| mpe.event_details.first.include? sha1 }.present?
  end

  def work_creation(event_start:, user_email:)
    { 'type' => 'Validation', 'start' => event_start, 'end' => DateTime.current, 'outcome' => 'Success',
      'details' => 'Submission package validated', 'software_version' => 'Curate v.1', 'user' => user_email }
  end

  def work_policy(event_start:, visibility:, user_email:)
    { 'type' => 'Policy Assignment', 'start' => event_start, 'end' => DateTime.current, 'outcome' => 'Success',
      'details' => "Visibility/access controls assigned: #{visibility}", 'software_version' => 'Curate v.1',
      'user' => user_email }
  end

  def work_update(event_start:, user_email:)
    { 'type' => 'Modification', 'start' => event_start, 'end' => DateTime.current, 'outcome' => 'Success',
      'details' => 'Object updated', 'software_version' => 'Curate v.1', 'user' => user_email }
  end

  private

    def active_fedora_create(object, event)
      object.preservation_event_attributes = [{ event_details:    event['details'],
                                                event_end:        event['end'] || DateTime.current,
                                                event_start:      event['start'],
                                                event_type:       event['type'],
                                                initiating_user:  event['user'],
                                                outcome:          event['outcome'],
                                                software_version: event['software_version'] }]

      object.save! if object.errors.empty? # save object only if there aren't any errors, eg: validation errors
    end

    def valkyrie_create(object, event)
      preservation_event = Hyrax.persister.save(resource: PreservationEventResource.new(
        event_details:    event['details'],
        event_end:        event['end'] || DateTime.current,
        event_start:      event['start'],
        event_type:       event['type'],
        initiating_user:  event['user'],
        outcome:          event['outcome'],
        software_version: event['software_version']
      ))
      object.preservation_event += [preservation_event]

      Hyrax.persister.save(resource: object)
    end
end
