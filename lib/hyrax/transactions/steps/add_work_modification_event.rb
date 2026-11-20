# frozen_string_literal: true

module Hyrax
  module Transactions
    module Steps
      ##
      # A step that attaches the work-level Modification preservation event to
      # an edited work before it is saved, as the AF CurateGenericWorkActor#update
      # does. Like AddWorkCreationEvents, adding it before the save keeps a
      # concurrent save of an earlier copy of the work from dropping it.
      #
      # Only edits pass the editing user; other callers of the update
      # transaction (attaching imported FileSets, batch edit, migration) do not
      # record a Modification event.
      class AddWorkModificationEvent
        include Dry::Monads[:result]
        include PreservationEvents

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [String, nil] initiating_user recorded on the event; without one
        #   no event is added
        def call(change_set, initiating_user: nil)
          work = change_set.model
          return Success(change_set) if initiating_user.blank? || !work.respond_to?(:preservation_event=)

          event = work_update(event_start: DateTime.current, user_email: initiating_user)
          work.preservation_event += [persist_valkyrie_preservation_event(event)]
          Success(change_set)
        rescue StandardError => e
          Failure["Failed to add work modification preservation event: #{e.message}", change_set]
        end
      end
    end
  end
end
