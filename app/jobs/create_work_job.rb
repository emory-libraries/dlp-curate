# frozen_string_literal: true
# [Hyrax-overwrite] Adds preservation_event on work creation
# This is a job spawned by the BatchCreateJob
class CreateWorkJob < Hyrax::ApplicationJob
  include PreservationEvents
  queue_as Hyrax.config.ingest_queue_name

  before_enqueue do |job|
    operation = job.arguments.last
    operation.pending_job(self)
  end

  # This copies metadata from the passed in attribute to all of the works that
  # are members of the given upload set
  # @param [User] user
  # @param [String] model
  # @param [Hash] attributes
  # @param [Hyrax::BatchCreateOperation] operation
  def perform(user, model, attributes, operation)
    operation.performing!
    work = model.constantize.new
    current_ability = Ability.new(user)
    env = Hyrax::Actors::Environment.new(work, current_ability, attributes)
    event_start = DateTime.current
    status = work_actor.create(env)
    event = { 'type' => 'Object Validation (Work created)', 'start' => event_start, 'outcome' => 'Success', 'details' => 'Valid submission package submitted', 'software_version' => 'Curate v.1',
              'user' => user.uid }
    create_preservation_event(work, event) if status
    return operation.success! if status
    operation.fail!(work.errors.full_messages.join(' '))
  end

  private

    def work_actor
      Hyrax::CurationConcern.actor
    end
end
