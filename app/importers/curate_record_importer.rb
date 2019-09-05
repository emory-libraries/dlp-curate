# frozen_string_literal: true

class CurateRecordImporter < Zizia::HyraxRecordImporter
  # Create a Hyrax::UploadedFile for each file attachment
  # TODO: What if we can't find the file?
  # TODO: How do we specify where the files can be found?
  # @param [Zizia::InputRecord]
  # @return [Array] an array of Hyrax::UploadedFile ids
  def create_upload_files(record)
    return unless record.mapper.respond_to?(:files)
    files_to_attach = record.mapper.files
    return [] if files_to_attach.nil? || files_to_attach.empty?
    uploaded_file_ids = []
    files_to_attach.each do |filename|
      next if filename.nil?
      uploaded_file = upload_file(filename)
      uploaded_file_ids << uploaded_file.id
    end
    uploaded_file_ids
  end

  def upload_file(filename)
    file_type = file_type(filename)
    uploaded_file = upload_preservation_master_file(filename) if file_type == "preservation_master_file"
    uploaded_file = upload_intermediate_file(filename) if file_type == "intermediate_file"
    uploaded_file
  end

  def upload_preservation_master_file(filename)
    file = File.open(find_file_path(filename))
    huf = Hyrax::UploadedFile.create(user: @depositor, preservation_master_file: file)
    file.close
    huf
  end

  def upload_intermediate_file(filename)
    file = File.open(find_file_path(filename))
    huf = Hyrax::UploadedFile.create(user: @depositor, intermediate_file: file)
    file.close
    huf
  end

  def file_type(filename)
    return "preservation_master_file" if filename.match?(/ARCH/)
    return "intermediate_file" if filename.match?(/PROD/)
    raise "Unrecognized file_type for filename #{filename}"
  end

  # Find the file according to the system in place on
  # /mnt/prodefs/Collections/dmfiles/MARBL/Manuscripts/MSS_1218_Langmuir
  # This will need to be updated for other collections if their files do not
  # follow the same organizational system.
  def find_file_path(filename)
    split = filename.split("_")
    kind_of_file = split.last.split(".").first # Is this an ARCH or a PROD file?
    directory_name = split[1] # e.g., "B001"
    File.join(ENV['IMPORT_PATH'], kind_of_file, directory_name, filename)
  end

  # Take a filename like "MSS1218_B001_I001_P0001_ARCH.tif" and get the first part,
  # so we can attach it to the object with identifier "MSS1218_B001_I001"
  def extract_call_number(filename)
    filename.split("_P00").first
  end

  ##
  # @param record [Zizia::InputRecord]
  # @return [ActiveFedora::Base]
  # Search for any existing records that match on the deduplication_field
  def find_existing_record(record)
    filename = record.mapper.metadata["Filename"]
    return if filename.nil?
    call_number = extract_call_number(filename)
    existing_records = CurateGenericWork.where(legacy_identifier: call_number)
    raise "More than one record matches call number #{call_number}" if existing_records.count > 1
    existing_records&.first
  end

  # When I have sequence number 1 and file ARCH, read the rest of the metadata
  # from the row and update the work's metadata.
  # For anything else, skip the metadata
  def skip_metadata?(update_record)
    filename = update_record.mapper.files.first
    split = filename.split("_")
    return true unless split.last.split(".").first == "ARCH"
    return true unless split[3].last == "1"
    false
  end

  # Update an existing object using the Hyrax actor stack
  # We assume the object was created as expected if the actor stack returns true.
  # Note that for now the update stack will only update metadata and update collection membership, it will not re-import files.
  def update_for(existing_record:, update_record:)
    Rails.logger.info "[zizia] event: record_update_started, batch_id: #{batch_id}, collection_id: #{collection_id}, #{deduplication_field}: #{update_record.respond_to?(deduplication_field) ? update_record.send(deduplication_field) : update_record}"

    additional_attrs = {
      uploaded_files: create_upload_files(update_record),
      depositor: @depositor.user_key,
      skip_metadata: skip_metadata?(update_record)
    }
    attrs = update_record.attributes.merge(additional_attrs)
    attrs = attrs.merge(member_of_collections_attributes: { '0' => { id: collection_id } }) if collection_id
    # Ensure nothing is passed in the files field,
    # since this is reserved for Hyrax and is where uploaded_files will be attached
    attrs.delete(:files)

    # We aren't using the attach remote files actor, so make sure any remote files are removed from the params before we try to save the object.
    attrs.delete(:remote_files)

    based_near = attrs.delete(:based_near)
    attrs = attrs.merge(based_near_attributes: based_near_attributes(based_near)) unless based_near.nil? || based_near.empty?

    actor_env = Hyrax::Actors::Environment.new(existing_record, ::Ability.new(@depositor), attrs)
    if Hyrax::CurationConcern.actor.update(actor_env)
      Rails.logger.info "[zizia] event: record_updated, batch_id: #{batch_id}, record_id: #{existing_record.id}, collection_id: #{collection_id}, #{deduplication_field}: #{existing_record.respond_to?(deduplication_field) ? existing_record.send(deduplication_field) : existing_record}"
      @success_count += 1
    else
      existing_record.errors.each do |attr, msg|
        Rails.logger.error "[zizia] event: validation_failed, batch_id: #{batch_id}, collection_id: #{collection_id}, attribute: #{attr.capitalize}, message: #{msg}, record_title: record_title: #{attrs[:title] ? attrs[:title] : attrs}"
      end
      @failure_count += 1
    end
  end
end
