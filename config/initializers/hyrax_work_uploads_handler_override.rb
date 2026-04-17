# frozen_string_literal: true
# [Hyrax-override-v5.2.0] Overrides WorkUploadsHandler to:
#   1. Create FileSetResource (not Hyrax::FileSet) with pcdm_use from fileset_use column
#   2. Use CurateValkyrieIngestJob for multi-file-per-FileSet ingest
#   3. Create preservation events for FileSet creation

if Hyrax.config.valkyrie_transition?
  Rails.application.config.to_prepare do
    Hyrax::WorkUploadsHandler.class_eval do
      include PreservationEvents

      private

        def make_file_set_and_ingest(file) # rubocop:disable Metrics/AbcSize
          event_start = DateTime.current
          file_set = @persister.save(resource: ::FileSetResource.new(file_set_args(file)))
          Hyrax.publisher.publish('object.deposited', object: file_set, user: file.user)
          record_file_submission_event(file_set, event_start, file)
          file.add_file_set!(file_set)

          Hyrax::AccessControlList.copy_permissions(source: target_permissions, target: file_set)

          file_set.visibility = file_set_extra_params(file)[:visibility] if file_set_extra_params(file)[:visibility].present?
          file_set.permission_manager.acl.save if file_set.permission_manager.acl.pending_changes?
          append_to_work(file_set)

          { file_set:, user: file.user, job: CurateValkyrieIngestJob.new(file) }
        end

        def file_set_args(file)
          {
            depositor:     file.user.user_key,
            creator:       file.user.user_key,
            date_uploaded: file.created_at,
            date_modified: Hyrax::TimeService.time_in_utc,
            label:         file_label(file),
            title:         file_label(file),
            pcdm_use:      file.fileset_use
          }
        end

        def file_label(file)
          file.uploader&.filename.presence || file.uploader&.file&.original_filename
        end

        def record_file_submission_event(file_set, event_start, file)
          outcome = file_set.persisted? ? 'Success' : 'Failure'
          create_preservation_event(file_set, submission_event_hash(file, event_start, outcome))
        end

        def submission_event_hash(file, event_start, outcome)
          file_name = file_label(file).to_s
          verb = outcome == 'Success' ? 'submitted for' : 'could not be submitted for'
          {
            'type' => 'File submission',
            'start' => event_start,
            'outcome' => outcome,
            'details' => "#{file_name} #{verb} preservation storage",
            'software_version' => "Fedora #{ENV.fetch('FEDORA_VERSION', 'v6.5.0')}",
            'user' => file.user.to_s
          }
        end
    end
  end
end
