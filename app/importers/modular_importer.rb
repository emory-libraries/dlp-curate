require 'zizia'

class ModularImporter
  attr_reader :csv_import, :collection_id,
              :user_id, :row

  attr_accessor :csv_import_detail

  DEDUPLICATION_FIELD = 'deduplication_key'.freeze

  def initialize(csv_import)
    @csv_import = csv_import
    @csv_file = csv_import.manifest.to_s
    @collection_id = csv_import.fedora_collection_id
    @user_id = csv_import.user_id
    @user_email = User.find(csv_import.user_id).email
  end

  def import
    raise "Cannot find expected input file #{@csv_file}" unless File.exist?(@csv_file)
    file = File.open(@csv_file)

    importer = Zizia::Importer.new(parser: Zizia::CsvParser.new(file: file), record_importer: {})

    work_id = nil
    importer.records.each do |record|
      case record.mapper.metadata['type']
      when 'work'
        # Gather the metadata from the custom methods and hash and combine into a single hash
        work = CurateGenericWork.new(record.mapper.send(:fields).map { |k| { "#{k}": record.mapper.try(k.to_sym) || record.mapper.metadata[k.to_s] } }.reduce({}, :merge))
        work.depositor = User.find(user_id).user_key
        work.save
        work_id = work.id
      when 'fileset'
        open_preservation_master_file = File.open(DeepFilePath.new(beginning: ENV['IMPORT_PATH'],
                                                                   ending: record.mapper.metadata['preservation_master_file']).to_s)
        open_intermediate_file = File.open(DeepFilePath.new(beginning: ENV['IMPORT_PATH'],
                                                            ending: record.mapper.metadata['intermediate_file']).to_s)
        uploaded_file = Hyrax::UploadedFile.create(user: User.find(user_id),
                                                   file: record.mapper.metadata['fileset_label'],
                                                   fileset_use: 'primary',
                                                   preservation_master_file: open_preservation_master_file,
                                                   intermediate_file: open_intermediate_file)

        AttachFilesToWorkJob.perform_now(CurateGenericWork.find(work_id), [uploaded_file])
        CurateGenericWork.find(work_id).reload
        open_preservation_master_file.close
        open_intermediate_file.close
      end
    end
  end
end
