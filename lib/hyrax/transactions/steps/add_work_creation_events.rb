# frozen_string_literal: true

module Hyrax
  module Transactions
    module Steps
      ##
      # A step that attaches the work-level Validation and Policy Assignment
      # preservation events to a new work before its first save. Adding them
      # after creation let a concurrent save of an earlier copy of the work
      # (e.g. a Bulkrax FileSet row's update_work) drop them.
      class AddWorkCreationEvents
        include Dry::Monads[:result]
        include PreservationEvents

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [String, nil] initiating_user recorded on the events; defaults
        #   to the change set's depositor
        def call(change_set, initiating_user: nil)
          work = change_set.model
          return Success(change_set) unless work.respond_to?(:preservation_event=)

          event_start = DateTime.current
          user = initiating_user.presence || change_set.depositor
          visibility = change_set.try(:visibility).presence || work.visibility
          events = [work_creation(event_start:, user_email: user),
                    work_policy(event_start:, visibility:, user_email: user)]
          work.preservation_event += events.map { |event| persist_valkyrie_preservation_event(event) }
          Success(change_set)
        rescue StandardError => e
          Failure["Failed to add work creation preservation events: #{e.message}", change_set]
        end
      end
    end
  end
end
