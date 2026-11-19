# frozen_string_literal: true
require 'net/http'
require 'uri'

# rubocop:disable Metrics/ClassLength
class DeleteActiveFedoraWorksJob < Hyrax::ApplicationJob
  def perform(af_works_csv:, user_id:)
    @af_works_csv = af_works_csv
    @ability = process_ability(user_id)

    CSV.open("config/emory/delete_af_works_results.csv", "a") do |reporting_csv|
      process_af_works_csv(reporting_csv)
    end
  end

  private

    # rubocop:disable Metrics/MethodLength
    def process_af_works_csv(reporting_csv)
      CSV.foreach(@af_works_csv, headers: true) do |row|
        work_attrs = row.to_hash
        @work_obj = ignore_errors { CurateGenericWork.find(work_attrs[:id]) }

        if @work_obj.nil?
          reporting_csv << [work_attrs[:id], work_attrs[:title_tesim], "A CurateGenericWork with this ID wasn't found."]
          next
        elsif @work_obj.deduplication_key != work_attrs[:deduplication_key_tesim]
          reporting_csv << [work_attrs[:id], work_attrs[:title_tesim], "The CurateGenericWork found has a deduplication_key that doesn't match the one provided in the CSV."]
          next
        else
          result = ignore_errors { delete_work_through_actor }

          if result.nil?
            reporting_csv << [work_attrs[:id], work_attrs[:title_tesim], "The deletion of the CurateGenericWork failed and will be removed via Solr."]
            process_solr_removal
            next
          else
            Hyrax.config.callback.run(:after_destroy, work_attrs[:id], @ability.current_user, warn: false)
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def delete_work_through_actor
      env = Hyrax::Actors::Environment.new(@work_obj, @ability, {})
      Hyrax::CurationConcern.actor.destroy(env)
    end

    def destroy_obj_attachments(obj)
      ignore_errors { obj.lease&.destroy }
      ignore_errors { obj.embargo&.destroy }
      ignore_errors { obj.access_control&.destroy }
    end

    def ignore_errors
      yield
    rescue Ldp::Gone, Ldp::HttpError, ActiveFedora::ObjectNotFoundError
      nil
    end

    def process_ability(user_id)
      Ability.new(User.find(user_id))
    end

    def process_solr_removal
      file_sets = @work_obj.member_ids.map { |id| FileSet.find(id) }
      destroy_obj_attachments(@work_obj)
      file_sets.each { |fs| destroy_obj_attachments(fs) }
      Hyrax.index_adapter.delete(resource: @work_obj)
      file_sets.each { |fs| Hyrax.index_adapter.delete(resource: fs) }
    end
end
