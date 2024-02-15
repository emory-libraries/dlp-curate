# frozen_string_literal: true

class WorkMembersCleanUpJob < Hyrax::ApplicationJob
  def perform(comma_separated_work_ids = nil)
    work_ids = comma_separated_work_ids&.split(',')
    raise 'The required work ids separated by commas were not provided.' if work_ids.blank?

    works = pull_works_by_ids(work_ids)
    works.each { |work| clean_up_work_member(work) }
  end

  def pull_works_by_ids(work_ids)
    ret_arr = []
    work_ids.each do |id|
      ret_arr << CurateGenericWork.find(id)
    rescue
      Rails.logger.error "The id #{id} did not match a work in the system."
      next
    end
    ret_arr
  end

  def clean_up_work_member(work)
    members_count = work.ordered_member_ids.size
    cleaned_member_ids = work.ordered_member_ids.compact.uniq

    if members_count != cleaned_member_ids.size
      ReplaceWorkMembersJob.perform_later(work, cleaned_member_ids)
    else
      Rails.logger.error 'No nil or duplicate work members were found.'
    end
  end
end
