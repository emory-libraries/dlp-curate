# frozen_string_literal: true

class CurateRecordImporter < Zizia::HyraxRecordImporter
  attr_accessor :csv_file

  def initialize(attributes: {})
    super
    @csv_file = attributes[:csv_file]
  end

  # Create a Hyrax::UploadedFile for each file attachment
  # TODO: What if we can't find the file?
  # TODO: How do we specify where the files can be found?
  # @param [Zizia::InputRecord]
  # @return [Array] an array of Hyrax::UploadedFile IDs
  def create_upload_files(record)
    return if record.mapper.metadata['type'] == 'fileset'
    files_to_attach = Zizia::CsvParser.new(file: @csv_file).records.map(&:mapper).select do |m|
      m.metadata['deduplication_key'] == record.mapper.metadata['deduplication_key']
    end.select(&:files)
    return [] if files_to_attach.nil? || files_to_attach.empty?
    uploaded_file_ids = []
    files_to_attach.each do |filename|
      next if filename.metadata['type'] == 'work'
      filenames = {}
      Curate::FILE_TYPES.each do |file_type|
        filenames[file_type] = filename.metadata[file_type] if filename.metadata[file_type]
      end
      filenames[:filename] = filename
      uploaded_prod_file = create_hyrax_uploaded_file(filenames)
      uploaded_file_ids << uploaded_prod_file.id
    end
    uploaded_file_ids
  end

  def create_hyrax_uploaded_file(filenames)
    open_files = {}
    Curate::FILE_TYPES.each do |file_type|
      open_files[file_type.to_sym] = File.open(find_file_path(filenames[file_type])) if File.exist?(find_file_path(filenames[file_type]))
    end
    huf = Hyrax::UploadedFile.create(user:                     @depositor,
                                     preservation_master_file: open_files[:preservation_master_file],
                                     intermediate_file:        open_files[:intermediate_file],
                                     service_file:             open_files[:service_file],
                                     extracted_text:           open_files[:extracted],
                                     transcript:               open_files[:transcript_file],
                                     fileset_use:              filenames[:filename].pcdm_use,
                                     file:                     filenames[:filename].metadata['fileset_label']) # this is the label
    Curate::FILE_TYPES.each do |file_type|
      open_files[file_type]&.close
    end
    huf
  end

  def process_attrs(record:)
    additional_attrs = {
      uploaded_files: create_upload_files(record),
      depositor:      depositor.user_key
    }

    attrs = record.attributes.merge(additional_attrs)
    attrs = attrs.merge(member_of_collections_attributes: { '0' => { id: collection_id } }) if collection_id
    attrs.delete(:pcdm_use)

    # Ensure nothing is passed in the files field,
    # since this is reserved for Hyrax and is where uploaded_files will be attached

    attrs.delete(:files)
    attrs.delete(:remote_files)
    based_near = attrs.delete(:based_near)
    attrs.merge(based_near_attributes: based_near_attributes(based_near)) unless based_near.nil? || based_near.empty?
    attrs
  end

  # Find the file according to the system in place on
  # /mnt/prodefs/Collections/dmfiles/MARBL/Manuscripts/MSS_1218_Langmuir
  # This will need to be updated for other collections if their files do not
  # follow the same organizational system.
  def find_file_path(filename)
    return '' unless filename
    File.join(ENV['IMPORT_PATH'], filename)
  end

  # Take a filename like "MSS1218_B001_I001_P0001_ARCH.tif" and get the first part,
  # so we can attach it to the object with identifier "MSS1218_B001_I001"
  def extract_call_number(filename)
    filename.split("_P00").first
  end

  # Update an existing object using the Hyrax actor stack
  # We assume the object was created as expected if the actor stack returns true.
  def update_for(existing_record:, update_record:)
    csv_import_detail.update_actor_stack = 'HyraxMetadataOnly' if csv_import_detail.update_actor_stack.nil?
    return if update_record.mapper.metadata['type'] == 'fileset'
    updater = case csv_import_detail.update_actor_stack
              when 'HyraxMetadataOnly'
                Zizia::HyraxMetadataOnlyUpdater.new(csv_import_detail: csv_import_detail,
                                                    existing_record:   existing_record,
                                                    update_record:     update_record,
                                                    attrs:             process_attrs(record: update_record))
              when 'HyraxDelete'
                Zizia::HyraxDeleteFilesUpdater.new(csv_import_detail: csv_import_detail,
                                                   existing_record:   existing_record,
                                                   update_record:     update_record,
                                                   attrs:             process_attrs(record: update_record))
              when 'HyraxOnlyNew'
                return unless existing_record[deduplication_field] != update_record.try(deduplication_field)
                Zizia::HyraxDefaultUpdater.new(csv_import_detail: csv_import_detail,
                                               existing_record:   existing_record,
                                               update_record:     update_record,
                                               attrs:             process_attrs(record: update_record))
              end
    updater.update
  end

  ##
  # @param record [Zizia::InputRecord]
  # @return [ActiveFedora::Base]
  # Search for any existing records that match on the deduplication_field
  def find_existing_record(record)
    existing_records = CurateGenericWork.where(deduplication_key: record.mapper.deduplication_key)
    existing_records&.first
  end
end
