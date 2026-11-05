# frozen_string_literal: true

class WorkMembersCleanUpJob < Hyrax::ApplicationJob
  include PullResourceOrAfObj

  def perform(comma_separated_work_ids = nil)
    work_ids = comma_separated_work_ids&.split(',')
    raise 'The required work ids separated by commas were not provided.' if work_ids.blank?

    works = pull_works_by_ids(work_ids)
    works.each { |work| clean_up_work_member(work) }
  end

  private

    def pull_works_by_ids(work_ids)
      work_ids.map do |id|
        pull_object_based_on_id(id:)
      rescue IneligibleIdError
        Rails.logger.error "The id #{id} did not match a work in the system."
        nil
      end.compact
    end

    def clean_up_work_member(work)
      member_ids = work.member_ids
      cleaned_member_ids = member_ids.compact.map(&:to_s).uniq

      if member_ids.size != cleaned_member_ids.size
        ReplaceWorkMembersJob.perform_later(work, cleaned_member_ids)
      else
        Rails.logger.error 'No nil or duplicate work members were found.'
      end
    end
end
