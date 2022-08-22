# frozen_string_literal: true

# [Hyrax-overwrite-v3.4.1] Attaching multiple files to single fileset
# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform(work, uploaded_files, **work_attributes)
    case work
    when ActiveFedora::Base
      perform_af(work, uploaded_files, work_attributes)
    else
      Hyrax::WorkUploadsHandler.new(work: work).add(files: uploaded_files).attach ||
        raise("Could not complete AttachFilesToWorkJob. Some of these are probably in an undesirable state: #{uploaded_files}")
    end
  end

  private

    def perform_af(work, uploaded_files, work_attributes)
      validate_files!(uploaded_files)
      depositor = proxy_or_depositor(work)
      user = User.find_by_user_key(depositor)

      work, work_permissions = create_permissions work, depositor
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.file_set_uri.present?

        attach_work(user, work, work_attributes, work_permissions, uploaded_file)
      end
    end

    def attach_work(user, work, work_attributes, work_permissions, uploaded_file)
      actor = Hyrax::Actors::FileSetActor.new(FileSet.create, user)
      file_set_attributes = file_set_attrs(work_attributes, uploaded_file)
      metadata = visibility_attributes(work_attributes, file_set_attributes)
      uploaded_file.add_file_set!(actor.file_set)
      actor.file_set.permissions_attributes = work_permissions
      actor.create_metadata(uploaded_file.fileset_use, metadata)
      actor.fileset_name(uploaded_file.file.to_s) if uploaded_file.file.present?
      preferred = preferred_file(uploaded_file)

      create_content_based_on_type(actor, uploaded_file, preferred)
      add_file_set_to_work_ordered_members(work, actor)
      actor.attach_to_work(work, metadata)
    end

    def create_content_based_on_type(actor, uploaded_file, preferred)
      actor.create_content(uploaded_file.preservation_master_file, preferred, :preservation_master_file) if uploaded_file.preservation_master_file.present?
      actor.create_content(uploaded_file.intermediate_file, preferred, :intermediate_file) if uploaded_file.intermediate_file.present?
      actor.create_content(uploaded_file.service_file, preferred, :service_file) if uploaded_file.service_file.present?
      actor.create_content(uploaded_file.extracted_text, preferred, :extracted) if uploaded_file.extracted_text.present?
      actor.create_content(uploaded_file.transcript, preferred, :transcript_file) if uploaded_file.transcript.present?
    end

    def add_file_set_to_work_ordered_members(work, actor)
      work.ordered_members << actor.file_set
      work.save
      actor.file_set.save
    end

    def create_permissions(work, depositor)
      work.edit_users += [depositor]
      work.edit_users = work.edit_users.dup
      work_permissions = work.permissions.map(&:to_hash)
      [work, work_permissions]
    end

    # The attributes used for visibility - sent as initial params to created FileSets.
    def visibility_attributes(attributes, file_set_attributes)
      attributes.merge(file_set_attributes).slice(:visibility, :visibility_during_lease,
                       :visibility_after_lease, :lease_expiration_date,
                       :embargo_release_date, :visibility_during_embargo,
                       :visibility_after_embargo)
    end

    def file_set_attrs(attributes, uploaded_file)
      attrs = Array(attributes[:file_set]).find { |fs| fs[:uploaded_file_id].present? && (fs[:uploaded_file_id].to_i == uploaded_file&.id) }
      Hash(attrs).symbolize_keys
    end

    def validate_files!(uploaded_files)
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.is_a? Hyrax::UploadedFile
        raise ArgumentError, "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
      end
    end

    ##
    # A work with files attached by a proxy user will set the depositor as the intended user
    # that the proxy was depositing on behalf of. See tickets #2764, #2902.
    def proxy_or_depositor(work)
      work.on_behalf_of.presence || work.depositor
    end

    def preferred_file(uploaded_file)
      preferred = if uploaded_file.service_file.present?
                    :service_file
                  elsif uploaded_file.intermediate_file.present?
                    :intermediate_file
                  else
                    :preservation_master_file
                  end
      preferred
    end
end
