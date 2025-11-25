# frozen_string_literal: true

# [Hyrax-overwrite-hyrax-v5.2.0]

module Hyrax
  module Actors
    # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
    class FileSetActor
      include Lockable
      include PreservationEvents
      attr_reader :file_set, :user, :attributes

      def initialize(file_set, user)
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
        return false unless file_set.save # Need to save to get an id
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

      def attach_to_work(work, file_set_params = {})
        # Note: This method no longer associates the file_set to the work. That happens
        #   in AttachFilesToWorkJob#add_file_set_to_work_ordered_members now. This has been changed
        #   so that Bulkrax can still use this actor and associate all of the file_sets
        #   to the work at the very end of the ingest process, which has shown significant
        #   processing time improvements.
        # Additional Note: The acquire_lock_for method has been removed from this process because its
        #   original purpose was to "ensure" that file_sets were truly associated to works successfully.
        #   The following processes do not tax the work's persistence, so that lock isn't needed here.
        #   It has also been our experience that locking objects to intensive processing backfires,
        #   due to the fact that all locks have a timeout mechanism that rarely allows for works to persist correctly.
        work.reload unless work.new_record?
        file_set.visibility = work.visibility unless assign_visibility?(file_set_params)
        assign_fileset_to_work_display_elements(work, file_set)
        work.save
      end

      def assign_fileset_to_work_display_elements(work, file_set)
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

      private

        def ability
          @ability ||= ::Ability.new(user)
        end

        # @param file_set [FileSet]
        # @return [ActiveFedora::Base]
        def parent_for(file_set:)
          file_set.parent
        end

        def build_file_actor(relation)
          file_actor_class.new(file_set, relation, user)
        end

        # uses create! because object must be persisted to serialize for jobs
        def wrapper!(file:, relation:, preferred:)
          JobIoWrapper.create_with_varied_file_handling!(user: user, file: file, relation: relation, file_set: file_set, preferred: preferred)
        end

        # For the label, use the original_filename or original_name if it's there.
        # If the file was imported via URL, parse the original filename.
        # If all else fails, use the basename of the file where it sits.
        # @note This is only useful for labeling the file_set, because of the recourse to import_url
        def label_for(file)
          # filename not present for uncached remote file!
          return uploaded_file_label(file) if file.is_a?(Hyrax::UploadedFile)
          # e.g. Hydra::Derivatives::IoDecorator
          return file.original_name if file.respond_to?(:original_name)
          # This path is taken when file is a Tempfile (e.g. from ImportUrlJob)
          return File.basename(Addressable::URI.unencode(file.file_url)) if file_set.import_url.present?
          File.basename(file.to_s)
        end

        def uploaded_file_label(file)
          file.uploader.filename.presence || File.basename(Addressable::URI.unencode(file.file_url))
        end

        def assign_visibility?(file_set_params = {})
          !((file_set_params || {}).keys.map(&:to_s) & %w[visibility embargo_release_date lease_expiration_date]).empty?
        end

        # replaces file_set.apply_depositor_metadata(user)from hydra-access-controls so depositor doesn't automatically get edit access
        def depositor_id(depositor)
          depositor.respond_to?(:user_key) ? depositor.user_key : depositor
        end

        # Must clear the fileset from the thumbnail_id, representative_id and rendering_ids fields on the work
        #   and force it to be re-solrized.
        # Although ActiveFedora clears the children nodes it leaves those fields in Solr populated.
        # rubocop:disable Metrics/CyclomaticComplexity
        def unlink_from_work
          work = parent_for(file_set: file_set)
          return unless work && (work.thumbnail_id == file_set.id || work.representative_id == file_set.id || work.rendering_ids.include?(file_set.id))
          work.thumbnail = nil if work.thumbnail_id == file_set.id
          work.representative = nil if work.representative_id == file_set.id
          work.rendering_ids -= [file_set.id]
          work.save!
        end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
