# frozen_string_literal: true
module Hyrax
  module Actors
    module FileSetActorToolbox
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
          fs = use_valkyrie ? file_set.valkyrie_resource : file_set
          file_actor_class.new(fs, relation, user, use_valkyrie: use_valkyrie)
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
          if file.is_a?(Hyrax::UploadedFile) # filename not present for uncached remote file!
            file.uploader.filename.presence || File.basename(Addressable::URI.unencode(file.file_url))
          elsif file.respond_to?(:original_name) # e.g. Hydra::Derivatives::IoDecorator
            file.original_name
          elsif file_set.import_url.present?
            # This path is taken when file is a Tempfile (e.g. from ImportUrlJob)
            File.basename(Addressable::URI.unencode(file.file_url))
          else
            # Convert to string since Hyrax::UploadedFileUploader object is passed and not raw file
            File.basename(file.to_s)
          end
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
          process_unlinking(work)
          work.save!
        end

        # switches between using valkyrie to save or active fedora to save
        def perform_save(object)
          obj_to_save = object_to_act_on(object)
          if valkyrie_object?(obj_to_save)
            saved_resource = Hyrax.persister.save(resource: obj_to_save)
            # return the same type of object that was passed in
            saved_object_to_return = valkyrie_object?(object) ? saved_resource : Wings::ActiveFedoraConverter.new(resource: saved_resource).convert
          else
            obj_to_save.save
            saved_object_to_return = obj_to_save
          end
          saved_object_to_return
        end

        # if passed a resource or if use_valkyrie==true, object to act on is the valkyrie resource
        def object_to_act_on(object)
          return object if valkyrie_object?(object)
          use_valkyrie ? object.valkyrie_resource : object
        end

        # determine if the object is a valkyrie resource
        def valkyrie_object?(object)
          object.is_a? Valkyrie::Resource
        end

        def process_unlinking(work)
          work.thumbnail = nil if work.thumbnail_id == file_set.id
          work.representative = nil if work.representative_id == file_set.id
          work.rendering_ids -= [file_set.id]
        end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
