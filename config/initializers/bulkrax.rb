# frozen_string_literal: true

Bulkrax.setup do |config|
  # Add local parsers
  # config.parsers += [
  #   { name: 'MODS - My Local MODS parser', class_name: 'Bulkrax::ModsXmlParser', partial: 'mods_fields' },
  # ]

  # WorkType to use as the default if none is specified in the import
  # Default is the first returned by Hyrax.config.curation_concerns
  config.default_work_type = 'FileSet'

  # Path to store pending imports
  config.import_path = 'imports'

  # Path to store exports before download
  # config.export_path = 'tmp/exports'

  # Server name for oai request header
  # config.server_name = 'my_server@name.com'

  # NOTE: Creating Collections using the collection_field_mapping will no longer be supported as of Bulkrax version 3.0.
  #       Please configure Bulkrax to use related_parents_field_mapping and related_children_field_mapping instead.
  # Field_mapping for establishing a collection relationship (FROM work TO collection)
  # This value IS NOT used for OAI, so setting the OAI parser here will have no effect
  # The mapping is supplied per Entry, provide the full class name as a string, eg. 'Bulkrax::CsvEntry'
  # The default value for CSV is collection
  # Add/replace parsers, for example:
  # config.collection_field_mapping['Bulkrax::RdfEntry'] = 'http://opaquenamespace.org/ns/set'

  # Field mappings
  # Create a completely new set of mappings by replacing the whole set as follows
  config.field_mappings = {
    "Bulkrax::CsvParser" => {
      "title" => { from: ["title"], parsed: true },
      "holding_repository" => { from: ["holding_repository"] },
      "date_created" => { from: ["date_created"] },
      "content_type" => { from: ["content_type"], parsed: true },
      "emory_rights_statements" => { from: ["emory_rights_statements"] },
      "rights_statement" => { from: ["rights_statement"], parsed: true },
      "data_classifications" => { from: ["data_classifications"], parsed: true, split: '\|' },
      "visibility" => { from: ["visibility"], parsed: true },
      "deduplication_key" => { from: ["deduplication_key"], source_identifier: true },
      "source_collection_id" => { from: ["source_collection_id"] },
      "pcdm_use" => { from: ["pcdm_use"], parsed: true },
      "file" => { from: ["file"], split: '\;' },
      "parent" => { from: ["parent"], related_parents_field_mapping: true },
      "model" => { from: ["model"] },
      "file_types" => { from: ["file_types"], split: '\|' }
    }
  }

  # Add to, or change existing mappings as follows
  #   e.g. to exclude date
  #   config.field_mappings["Bulkrax::OaiDcParser"]["date"] = { from: ["date"], excluded: true  }
  #
  #   e.g. to import parent-child relationships
  #   config.field_mappings['Bulkrax::CsvParser']['parents'] = { from: ['parents'], related_parents_field_mapping: true }
  #   config.field_mappings['Bulkrax::CsvParser']['children'] = { from: ['children'], related_children_field_mapping: true }
  #   (For more info on importing relationships, see Bulkrax Wiki: https://github.com/samvera-labs/bulkrax/wiki/Configuring-Bulkrax#parent-child-relationship-field-mappings)
  #
  # #   e.g. to add the required source_identifier field
  #   #   config.field_mappings["Bulkrax::CsvParser"]["source_id"] = { from: ["old_source_id"], source_identifier: true  }
  # If you want Bulkrax to fill in source_identifiers for you, see below

  # To duplicate a set of mappings from one parser to another
  #   config.field_mappings["Bulkrax::OaiOmekaParser"] = {}
  #   config.field_mappings["Bulkrax::OaiDcParser"].each {|key,value| config.field_mappings["Bulkrax::OaiOmekaParser"][key] = value }

  # Should Bulkrax make up source identifiers for you? This allow round tripping
  # and download errored entries to still work, but does mean if you upload the
  # same source record in two different files you WILL get duplicates.
  # It is given two aruguments, self at the time of call and the index of the reocrd
  config.fill_in_blank_source_identifiers = ->(obj, index) { "Curate-#{obj.importerexporter.id}-#{index}" }

  # Properties that should not be used in imports/exports. They are reserved for use by Hyrax.
  # config.reserved_properties += ['my_field']

  # List of Questioning Authority properties that are controlled via YAML files in
  # the config/authorities/ directory. For example, the :rights_statement property
  # is controlled by the active terms in config/authorities/rights_statements.yml
  # Defaults: 'rights_statement' and 'license'
  # config.qa_controlled_properties += ['my_field']
end

# Sidebar for hyrax 3+ support
if Object.const_defined?(:Hyrax) && ::Hyrax::DashboardController&.respond_to?(:sidebar_partials)
  Hyrax::DashboardController.sidebar_partials[:repository_content] << "hyrax/dashboard/sidebar/bulkrax_sidebar_additions"
end

require_relative '../../lib/importing_modules/file_set_methods'

# rubocop:disable Metrics/BlockLength
Bulkrax::ObjectFactory.class_eval do
  include FileSetMethods
  attr_reader :attributes, :object, :source_identifier_value, :klass, :replace_files, :update_files, :work_identifier, :related_parents_parsed_mapping, :importer_run_id, :parser

  # Bulkrax v4.2.1 Override: as mentioned below, this method's largely mimicing AttachFilesToWorkJob,
  #   which we have extensively customized in Curate to accomodate our needs. Here,
  #   we are purely adapting those customizations.
  #   TODO: To DRY up this code, we should shoot for refactoring these processes into
  #   a reusable module.
  # This method is heavily inspired by Hyrax's AttachFilesToWorkJob
  def create_file_set(attrs)
    _, @work = find_record(attributes[related_parents_parsed_mapping].first, importer_run_id)
    work_permissions = @work.permissions.map(&:to_hash)
    attrs = clean_attrs(attrs)
    file_set_attrs = attrs.slice(*object.attributes.keys)
    object.assign_attributes(file_set_attrs)
    uploaded_files = attrs['uploaded_files'].map { |ufid| ::Hyrax::UploadedFile.find(ufid) }
    @preferred = preferred_file(uploaded_files)

    attrs['uploaded_files'].each do |uploaded_file_id|
      @uploaded_file = ::Hyrax::UploadedFile.find(uploaded_file_id)
      next if @uploaded_file.file_set_uri.present?

      process_uploaded_file(work_permissions, file_set_attrs)
    end

    object.save!
  end

  # Overridden because we need parser to process filetypes.
  # rubocop:disable Metrics/ParameterLists
  def initialize(
    attributes:,
    source_identifier_value:,
    work_identifier:,
    parser:,
    related_parents_parsed_mapping: nil,
    replace_files:                  false,
    user:                           nil,
    klass:                          nil,
    importer_run_id:                nil,
    update_files:                   false
  )
    @attributes = ActiveSupport::HashWithIndifferentAccess.new(attributes)
    @replace_files = replace_files
    @update_files = update_files
    @user = user || User.batch_user
    @work_identifier = work_identifier
    @related_parents_parsed_mapping = related_parents_parsed_mapping
    @source_identifier_value = source_identifier_value
    @klass = klass || Bulkrax.default_work_type.constantize
    @importer_run_id = importer_run_id
    @parser = parser
  end
  # rubocop:enable Metrics/ParameterLists

  # This overrides the method included in this class by the module Bulkrax::FileFactory.
  # This is needed so that we can distinguish between preservation_master_file, intermediate_file,
  # service_file, extracted_text, and transcript (#process_file_types).
  def import_file(path)
    u = Hyrax::UploadedFile.new
    u.user_id = @user.id
    u.send("#{process_file_types(path.split('/').last)}=", CarrierWave::SanitizedFile.new(path))
    update_filesets(u)
  end
end
# rubocop:enable Metrics/BlockLength

Bulkrax::CsvEntry.class_eval do
  def factory
    @factory ||= Bulkrax::ObjectFactory.new(
      attributes:                     parsed_metadata,
      source_identifier_value:        identifier,
      work_identifier:                parser.work_identifier,
      related_parents_parsed_mapping: parser.related_parents_parsed_mapping,
      replace_files:                  replace_files,
      user:                           user,
      klass:                          factory_class,
      importer_run_id:                importerexporter.last_run.id,
      update_files:                   update_files,
      parser:                         parser
    )
  end
end

Bulkrax::CsvParser.class_eval do
  # This is the fix present in v4.3.0
  # Retrieve the path where we expect to find the files
  def path_to_files(**args)
    filename = args.fetch(:filename, '')

    return @path_to_files if @path_to_files.present? && filename.blank?
    @path_to_files = File.join(
        zip? ? importer_unzip_path : File.dirname(import_file_path), 'files', filename
      )
  end
end

Bulkrax::ScheduleRelationshipsJob.class_eval do
  def perform(importer_id:)
    importer = ::Bulkrax::Importer.find(importer_id)
    pending_num = importer.entries.left_outer_joins(:latest_status)
                          .where('bulkrax_statuses.status_message IS NULL ').count
    return reschedule(importer_id) unless pending_num.zero?

    importer.last_run.parents.each do |parent_id|
      ::AssociateFilesetsWithWorkJob.perform_later(importer)
      ::Bulkrax::CreateRelationshipsJob.perform_later(parent_identifier: parent_id, importer_run_id: importer.last_run.id)
    end
  end
end
