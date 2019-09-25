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
      uploaded_file = upload_file(filename)
      next unless uploaded_file
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
    create_hyrax_uploaded_file(filename: filename, type: :preservation_master_file)
  end

  def upload_intermediate_file(filename)
    create_hyrax_uploaded_file(filename: filename, type: :intermediate_file)
  end

  def create_hyrax_uploaded_file(filename:, type:)
    return unless File.exist?(find_file_path(filename))
    file = File.open(find_file_path(filename))
    huf = Hyrax::UploadedFile.create(:user => @depositor, type => file, :fileset_use => FileSet::PRIMARY, :file => fileset_label(filename))
    file.close
    huf
  end

  def process_attrs(record:)
    additional_attrs = {
      uploaded_files: create_upload_files(record),
      depositor: depositor.user_key
    }

    attrs = record.attributes.merge(additional_attrs)
    attrs = attrs.merge(member_of_collections_attributes: { '0' => { id: collection_id } }) if collection_id

    # Ensure nothing is passed in the files field,
    # since this is reserved for Hyrax and is where uploaded_files will be attached
    attrs.delete(:files)
    attrs.delete(:remote_files)
    based_near = attrs.delete(:based_near)
    attrs.merge(skip_metadata: skip_metadata?(record))
    attrs.merge(based_near_attributes: based_near_attributes(based_near)) unless based_near.nil? || based_near.empty?
    attrs
  end

  # Convert the "part" section of the filename to a number and use it to generate
  # the fileset label
  # Return the filename as the label if anything goes wrong.
  def fileset_label(filename)
    part = filename.split("_")[3]
    part_number = part.delete("P").to_i
    return "Front" if part_number == 1
    return "Back" if part_number == 2
    part
  rescue
    filename
  end

  def file_type(filename)
    return if filename.nil?
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

  # Update an existing object using the Hyrax actor stack
  # We assume the object was created as expected if the actor stack returns true.
  def update_for(existing_record:, update_record:)
    files_only_check(update_record: update_record)
    updater = case csv_import_detail.update_actor_stack
              when 'HyraxMetadataOnly'
                Zizia::HyraxMetadataOnlyUpdater.new(csv_import_detail: csv_import_detail,
                                                    existing_record: existing_record,
                                                    update_record: update_record,
                                                    attrs: process_attrs(record: update_record))
              when 'HyraxDelete'
                Zizia::HyraxDeleteFilesUpdater.new(csv_import_detail: csv_import_detail,
                                                   existing_record: existing_record,
                                                   update_record: update_record,
                                                   attrs: process_attrs(record: update_record))
              when 'HyraxOnlyNew'
                return unless existing_record[deduplication_field] != update_record.try(deduplication_field)
                Zizia::HyraxDefaultUpdater.new(csv_import_detail: csv_import_detail,
                                               existing_record: existing_record,
                                               update_record: update_record,
                                               attrs: process_attrs(record: update_record))
              when 'CurateFilesOnly'
                Zizia::HyraxDefaultUpdater.new(csv_import_detail: csv_import_detail,
                                               existing_record: existing_record,
                                               update_record: update_record,
                                               attrs: process_attrs(record: update_record))
              end
    updater.update
  end

  ##
  # @param record [Zizia::InputRecord]
  # @return [ActiveFedora::Base]
  # Search for any existing records that match on the deduplication_field
  def find_existing_record(record)
    filename = record.mapper.metadata["Filename"]
    return if filename.nil?
    call_number = extract_call_number(filename)
    existing_records = CurateGenericWork.where(other_identifiers: call_number)
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

  def files_only_check(update_record:)
    return unless skip_metadata?(update_record)
    csv_import_detail.update_actor_stack = 'CurateFilesOnly'
    csv_import_detail.save
  end
end
