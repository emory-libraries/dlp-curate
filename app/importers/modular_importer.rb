# frozen_string_literal: true

require 'zizia'

class ModularImporter
  attr_reader :csv_import, :collection_id,
              :user_id, :row, :open_csv_file

  attr_accessor :csv_import_detail, :mapper, :work, :work_id, :uploaded_file, :related_rows

  DEDUPLICATION_FIELD = 'deduplication_key'

  def initialize(csv_import)
    @csv_import = csv_import
    @csv_file = csv_import.manifest.to_s
    @collection_id = csv_import.fedora_collection_id
    @user_id = csv_import.user_id
    @user_email = User.find(csv_import.user_id).email
    @open_csv_file = File.open(@csv_file)
    @deduplication_field = DEDUPLICATION_FIELD
    @row_number = 1
  end

  def import
    check_for_exisiting_csv_file
    @work_id = nil
    importer.records.each do |record|
      @mapper = record.mapper
      case mapper.metadata['type']
      when 'work'
        rows_from_key(key: mapper.metadata['deduplication_key'])
        save_work
        related_rows.pop
      when 'fileset'
        attach_files
        related_rows.pop
      end
    end
  end

  def importer
    Zizia::Importer.new(parser: Zizia::CsvParser.new(file: open_csv_file), record_importer: {})
  end

  def check_for_exisiting_csv_file
    raise "Cannot find expected input file #{csv_file}" unless File.exist?(open_csv_file)
  end

  def work_metadata
    mapper.send(:fields).map { |k| { "#{k}": mapper.try(k.to_sym) || mapper.metadata[k.to_s] } }.reduce({}, :merge)
  end

  def create_work_from_mapper_metadata
    CurateGenericWork.new(work_metadata)
  end

  def save_work
    @work = create_work_from_mapper_metadata
    work.depositor = User.find(user_id).user_key
    work.save
    @work_id = work.id
  end

  def open_preservation_master_file
    File.open(DeepFilePath.new(beginning: ENV['IMPORT_PATH'],
                               ending: mapper.metadata['preservation_master_file']).to_s)
  end

  def open_intermediate_file
    File.open(DeepFilePath.new(beginning: ENV['IMPORT_PATH'],
                               ending: mapper.metadata['intermediate_file']).to_s)
  end

  def create_hyrax_uploaded_file
    Hyrax::UploadedFile.create(user: User.find(user_id),
                               file: mapper.metadata['fileset_label'],
                               fileset_use: 'primary',
                               preservation_master_file: open_preservation_master_file,
                               intermediate_file: open_intermediate_file)
  end

  def attach_files
    @uploaded_file = create_hyrax_uploaded_file
    add_to_collection
    AttachFilesToWorkJob.perform_now(CurateGenericWork.find(work_id), [uploaded_file])
    open_preservation_master_file.close
    open_intermediate_file.close
    CurateGenericWork.find(work_id).save
  end

  def add_to_collection
    return unless collection_id
    collection = Collection.find(collection_id)
    work = CurateGenericWork.find(work_id)
    work.member_of_collections << collection
    collection.save
  end

  def existing_work
    CurateGenericWork.where(deduplication_key: @mapper.metadata['deduplication_key'])
  end

  def rows_from_key(key:)
    @related_rows = importer.parser.records.collect { |m| m.mapper.metadata }.collect { |r| r['deduplication_key'] == key }
  end
end
