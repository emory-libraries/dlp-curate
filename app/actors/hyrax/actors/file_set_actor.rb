# frozen_string_literal: true
# [Hyrax-overwrite-v3.0.2]
module Hyrax
  module Actors
    # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
    class FileSetActor
      include Lockable
      include PreservationEvents
      include Hyrax::Actors::FileSetActorToolbox
      attr_reader :file_set, :user, :attributes, :use_valkyrie

      def initialize(file_set, user, use_valkyrie: false)
        @use_valkyrie = use_valkyrie
        @file_set = file_set
        @user = user
      end

      # @!group Asynchronous Operations

      # Spawns asynchronous IngestJob unless ingesting from URL
      # Called from FileSetsController, AttachFilesToWorkJob, IngestLocalFileJob, ImportUrlJob
      # @param [Hyrax::UploadedFile, File] file the file uploaded by the user
      # @param [Symbol, #to_s] relation
      # @return [IngestJob, FalseClass] false on failure, otherwise the queued job
      def create_content(file, preferred, relation = :preservation_master_file, from_url: false)
        # If the file set doesn't have a title or label assigned, set a default.
        file_set.label ||= label_for(file)
        file_set.title = [file_set.label] if file_set.title.blank?
        @file_set = perform_save(file_set)
        return false unless file_set
        file_actor = build_file_actor(relation)
        io_wrapper = wrapper!(file: file, relation: relation, preferred: preferred)
        if from_url
          # If ingesting from URL, don't spawn an IngestJob; instead
          # reach into the FileActor and run the ingest with the file instance in
          # hand. Do this because we don't have the underlying UploadedFile instance
          file_actor.ingest_file(wrapper!(file: file, relation: relation, preferred: preferred))
          parent = parent_for(file_set: file_set)
          VisibilityCopyJob.perform_later(parent)
          InheritPermissionsJob.perform_later(parent)
        else
          IngestJob.perform_later(io_wrapper)
        end
      end

      def fileset_name(fsn)
        file_set.label ||= fsn
        file_set.title = [file_set.label] if file_set.title.blank?
      end

      # Spawns asynchronous IngestJob with user notification afterward
      # @param [Hyrax::UploadedFile, File, ActionDigest::HTTP::UploadedFile] file the file uploaded by the user
      # @param [Symbol, #to_s] relation
      # @return [IngestJob] the queued job
      def update_content(file, preferred, relation = :preservation_master_file)
        IngestJob.perform_later(wrapper!(file: file, relation: relation, preferred: preferred), notification: true)
      end
      # @!endgroup

      # Adds the appropriate metadata, visibility and relationships to file_set
      # @note In past versions of Hyrax this method did not perform a save because it is mainly used in conjunction with
      #   create_content, which also performs a save.  However, due to the relationship between Hydra::PCDM objects,
      #   we have to save both the parent work and the file_set in order to record the "metadata" relationship between them.
      # @param [Hash] file_set_params specifying the visibility, lease and/or embargo of the file set.
      #   Without visibility, embargo_release_date or lease_expiration_date, visibility will be copied from the parent.
      def create_metadata(fileset_use, file_set_params = {})
        file_set.depositor = depositor_id(user)
        now = TimeService.time_in_utc
        file_set.date_uploaded = now
        file_set.date_modified = now
        file_set.creator = [user.user_key]
        file_set.pcdm_use = fileset_use
        if assign_visibility?(file_set_params)
          env = Actors::Environment.new(file_set, ability, file_set_params)
          CurationConcern.file_set_create_actor.create(env)
        end
        yield(file_set) if block_given?
      end

      # Locks to ensure that only one process is operating on the list at a time.
      def attach_to_work(work, file_set_params = {})
        acquire_lock_for(work.id) do
          # Ensure we have an up-to-date copy of the members association, so that we append to the end of the list.
          attach_to_af_work(work, file_set_params)
          Hyrax.config.callback.run(:after_create_fileset, file_set, user, warn: false)
        end
      end
      alias attach_file_to_work attach_to_work
      deprecation_deprecate attach_file_to_work: "use attach_to_work instead"

      # Adds a FileSet to the work using ore:Aggregations.
      def attach_to_af_work(work, file_set_params)
        work.reload unless work.new_record?
        process_work_attachment(work, file_set_params)
        # Save the work so the association between the work and the file_set is persisted (head_id)
        # NOTE: the work may not be valid, in which case this save doesn't do anything.
        work.save
      end

      def process_work_attachment(work, file_set_params)
        file_set.visibility = work.visibility unless assign_visibility?(file_set_params)
        work.representative = file_set if work.representative_id.blank?
        work.thumbnail = file_set if work.thumbnail_id.blank?
      end

      # @param [String] revision_id the revision to revert to
      # @param [Symbol, #to_sym] relation
      # @return [Boolean] true on success, false otherwise
      def revert_content(revision_id, relation = :original_file)
        return false unless build_file_actor(relation).revert_to(revision_id)
        Hyrax.config.callback.run(:after_revert_content, file_set, user, revision_id, warn: false)
        true
      end

      def update_metadata(attributes)
        env = Actors::Environment.new(file_set, ability, attributes)
        CurationConcern.file_set_update_actor.update(env)
      end

      def destroy
        unlink_from_work
        file_set.destroy
        Hyrax.config.callback.run(:after_destroy, file_set.id, user, warn: false)
      end

      class_attribute :file_actor_class
      self.file_actor_class = Hyrax::Actors::FileActor
    end
  end
end
