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
      "abstract" => { from: ["abstract"] },
      "access_restriction_notes" => { from: ["access_restriction_notes"], split: '\|', join: '|' },
      "administrative_unit" => { from: ["administrative_unit"], parsed: true },
      "author_notes" => { from: ["author_notes"] },
      "conference_dates" => { from: ["conference_dates"] },
      "conference_name" => { from: ["conference_name"] },
      "contact_information" => { from: ["contact_information"] },
      "content_genres" => { from: ["content_genres"], split: '\|', join: '|' },
      "content_type" => { from: ["content_type"], parsed: true },
      "contributors" => { from: ["contributors"], split: '\|', join: '|' },
      "copyright_date" => { from: ["copyright_date"] },
      "creator" => { from: ["creator"], split: '\|', join: '|' },
      "data_classifications" => { from: ["data_classifications"], parsed: true, split: '\|', join: '|' },
      "data_collection_dates" => { from: ["data_collection_dates"], split: '\|', join: '|' },
      "data_producers" => { from: ["data_producers"], split: '\|', join: '|' },
      "data_source_notes" => { from: ["data_source_notes"], split: '\|', join: '|' },
      "date_created" => { from: ["date_created"], join: '|' },
      "date_digitized" => { from: ["date_digitized"] },
      "date_issued" => { from: ["date_issued"] },
      "deduplication_key" => { from: ["deduplication_key"], source_identifier: true },
      "edition" => { from: ["edition"] },
      "emory_ark" => { from: ["emory_ark"], split: '\|', join: '|' },
      "emory_rights_statements" => { from: ["emory_rights_statements"], split: '\|', join: '|' },
      "extent" => { from: ["extent"] },
      "file" => { from: ["file"], split: '\;', join: ';' },
      "file_types" => { from: ["file_types"], split: '\|', join: '|' },
      "final_published_versions" => { from: ["final_published_versions"], split: '\|', join: '|' },
      "geographic_unit" => { from: ["geographic_unit"] },
      "grant_agencies" => { from: ["grant_agencies"], split: '\|', join: '|' },
      "grant_information" => { from: ["grant_information"], split: '\|', join: '|' },
      "holding_repository" => { from: ["holding_repository"], join: '|' },
      "institution" => { from: ["institution"] },
      "internal_rights_note" => { from: ["internal_rights_note"] },
      "isbn" => { from: ["isbn"] },
      "issn" => { from: ["issn"] },
      "issue" => { from: ["issue"] },
      "keywords" => { from: ["keywords"], split: '\|', join: '|' },
      "legacy_rights" => { from: ["legacy_rights"] },
      "local_call_number" => { from: ["local_call_number"] },
      "model" => { from: ["model"] },
      "notes" => { from: ["notes"], split: '\|', join: '|' },
      "other_identifiers" => { from: ["other_identifiers"], split: '\|', join: '|' },
      "page_range_end" => { from: ["page_range_end"] },
      "page_range_start" => { from: ["page_range_start"] },
      "parent" => { from: ["parent"], related_parents_field_mapping: true },
      "parent_title" => { from: ["parent_title"] },
      "pcdm_use" => { from: ["pcdm_use"], parsed: true },
      "place_of_production" => { from: ["place_of_production"] },
      "primary_language" => { from: ["primary_language"] },
      "primary_repository_ID" => { from: ["primary_repository_ID"] },
      "publisher" => { from: ["publisher"] },
      "publisher_version" => { from: ["publisher_version"], parsed: true },
      "re_use_license" => { from: ["re_use_license"], parsed: true },
      "related_datasets" => { from: ["related_datasets"], split: '\|', join: '|' },
      "related_material_notes" => { from: ["related_material_notes"], split: '\|', join: '|' },
      "related_publications" => { from: ["related_publications"], split: '\|', join: '|' },
      "rights_documentation" => { from: ["rights_documentation"] },
      "rights_holders" => { from: ["rights_holders"], split: '\|', join: '|' },
      "rights_statement" => { from: ["rights_statement"], split: '\|', join: '|', parsed: true },
      "scheduled_rights_review" => { from: ["scheduled_rights_review"] },
      "scheduled_rights_review_note" => { from: ["scheduled_rights_review_note"] },
      "sensitive_material" => { from: ["sensitive_material"], parsed: true },
      "sensitive_material_note" => { from: ["sensitive_material_note"] },
      "series_title" => { from: ["series_title"] },
      "source_collection_id" => { from: ["source_collection_id"] },
      "sponsor" => { from: ["sponsor"] },
      "staff_notes" => { from: ["staff_notes"], split: '\|', join: '|' },
      "subject_geo" => { from: ["subject_geo"], split: '\|', join: '|' },
      "subject_names" => { from: ["subject_names"], split: '\|', join: '|' },
      "subject_time_periods" => { from: ["subject_time_periods"], split: '\|', join: '|' },
      "subject_topics" => { from: ["subject_topics"], split: '\|', join: '|' },
      "sublocation" => { from: ["sublocation"] },
      "system_of_record_ID" => { from: ["system_of_record_ID"] },
      "table_of_contents" => { from: ["table_of_contents"] },
      "technical_note" => { from: ["technical_note"] },
      "title" => { from: ["title"], parsed: true, split: '\|', join: '|' },
      "transfer_engineer" => { from: ["transfer_engineer"] },
      "uniform_title" => { from: ["uniform_title"] },
      "visibility" => { from: ["visibility"], parsed: true },
      "volume" => { from: ["volume"] }
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

require_relative '../../lib/bulkrax/override_assistive_methods'

# rubocop:disable Metrics/BlockLength
Bulkrax::ObjectFactory.class_eval do
  include OverrideAssistiveMethods
  attr_reader :attributes, :object, :source_identifier_value, :klass, :replace_files, :update_files, :work_identifier, :related_parents_parsed_mapping, :importer_run_id, :parser

  # Bulkrax v4.3.0 Override: as mentioned below, this method's largely mimicing AttachFilesToWorkJob,
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

    uploaded_files.each do |uploaded_file|
      @uploaded_file = uploaded_file
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

  # Override if we need to map the attributes from the parser in
  # a way that is compatible with how the factory needs them.
  def transform_attributes(update: false)
    @transform_attributes = attributes.slice(*permitted_attributes)
    @transform_attributes.merge!(file_attributes(update_files)) if with_files
    @transform_attributes = remove_blank_hash_values(@transform_attributes)
    update ? @transform_attributes.except(:id) : @transform_attributes
  end
end
# rubocop:enable Metrics/BlockLength

Bulkrax::CsvEntry.class_eval do
  include OverrideAssistiveMethods

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

  def build_export_metadata
    self.parsed_metadata = {}

    build_system_metadata
    build_files_metadata unless hyrax_record.is_a?(Collection)
    build_relationship_metadata
    build_mapping_metadata
    build_preservation_workflow_metadata if hyrax_record.is_a?(CurateGenericWork)
    save!

    parsed_metadata
  end

  def build_files_metadata
    # attaching files to the FileSet row only so we don't have duplicates when importing to a new tenant
    if hyrax_record.work?
      build_thumbnail_files
    else
      file_mapping = key_for_export('file')
      file_sets = hyrax_record.file_set? ? Array.wrap(hyrax_record) : hyrax_record.file_sets
      filenames_with_types = map_file_sets(file_sets)
      only_filenames = filenames_with_types.map { |str| str.split("|").map { |fwt| fwt.split(":").first }.join(';') }

      handle_join_on_export(file_mapping, only_filenames, mapping['file']&.[]('join'))
      handle_join_on_export('file_types', filenames_with_types, '|')
    end
  end

  def build_relationship_metadata
    # Includes all relationship methods for all exportable record types (works, Collections, FileSets)
    relationship_methods = {
      related_parents_parsed_mapping => %i[member_of_collection_ids member_of_work_ids in_work_ids],
      related_children_parsed_mapping => %i[member_collection_ids member_work_ids file_set_ids]
    }

    relationship_methods.each do |relationship_key, methods|
      next if relationship_key.blank?

      values = []
      methods.each do |m|
        values << hyrax_record.public_send(m) if hyrax_record.respond_to?(m)
      end
      values = values.flatten.uniq
      next if values.blank?

      handle_join_on_export(relationship_key, values, '|')
    end
  end

  def build_value(key, value)
    data = hyrax_record.send(key.to_s)
    if data.is_a?(ActiveTriples::Relation)
      build_triples_value(key, value, data)
    elsif key == 'visibility'
      parsed_metadata[key_for_export(key)] = CurateMapper.new.visibility_mapping.key(data).titleize
    else
      parsed_metadata[key_for_export(key)] = prepare_export_data(data)
    end
  end

  def handle_join_on_export(key, values, join)
    if join
      parsed_metadata[key] = values.join(join)
    else
      values.each_with_index do |value, i|
        parsed_metadata["#{key}_#{i + 1}"] = value
      end
      parsed_metadata.delete(key)
    end
  end
end

Bulkrax::CsvParser.class_eval do
  include OverrideAssistiveMethods

  alias create_from_object_ids create_new_entries

  def create_entry_and_job(current_record, type)
    new_entry = find_or_create_entry(send("#{type}_entry_class"),
                                     current_record[source_identifier]&.strip,
                                     'Bulkrax::Importer',
                                     current_record.to_h)
    if current_record[:delete].present?
      "Bulkrax::Delete#{type.camelize}Job".constantize.send(perform_method, new_entry, current_run)
    else
      "Bulkrax::Import#{type.camelize}Job".constantize.send(perform_method, new_entry.id, current_run.id)
    end
  end

  def current_record_ids
    @work_ids = []
    @collection_ids = []
    @file_set_ids = []

    case importerexporter.export_from
    when 'all'
      @work_ids = ActiveFedora::SolrService.query("has_model_ssim:(#{Hyrax.config.curation_concerns.join(' OR ')}) #{extra_filters}", method: :post, rows: 2_147_483_647).map(&:id)
      @collection_ids = ActiveFedora::SolrService.query("has_model_ssim:Collection #{extra_filters}", method: :post, rows: 2_147_483_647).map(&:id)
      @file_set_ids = ActiveFedora::SolrService.query("has_model_ssim:FileSet #{extra_filters}", method: :post, rows: 2_147_483_647).map(&:id)
    when 'collection'
      work_id_query = "member_of_collection_ids_ssim:#{importerexporter.export_source + extra_filters} AND has_model_ssim:(#{Hyrax.config.curation_concerns.join(' OR ')})"
      @work_ids = ActiveFedora::SolrService
                  .query(work_id_query, method: :post, rows: 2_000_000_000)
                  .map(&:id)
      # get the parent collection and child collections
      @collection_ids = ActiveFedora::SolrService.query("id:#{importerexporter.export_source} #{extra_filters}", method: :post, rows: 2_147_483_647).map(&:id)
      @collection_ids += ActiveFedora::SolrService.query("has_model_ssim:Collection AND member_of_collection_ids_ssim:#{importerexporter.export_source}", method: :post, rows: 2_147_483_647).map(&:id)
      find_child_file_sets(@work_ids)
    when 'object_ids'
      process_current_record_object_ids
    when 'worktype'
      @work_ids = ActiveFedora::SolrService.query("has_model_ssim:#{importerexporter.export_source + extra_filters}", method: :post, rows: 2_000_000_000).map(&:id)
      find_child_file_sets(@work_ids)
    when 'importer'
      set_ids_for_exporting_from_importer
    end

    @work_ids + @collection_ids + @file_set_ids
  end

  # Bulkrax v4.3.0 Override: swaps out Bulkrax' sorting for our own, grouping together
  #   CurateGenericWorks with their associated FileSets.
  # rubocop:disable Metrics/MethodLength
  def write_files
    require 'open-uri'
    folder_count = 0
    entries_to_write = sort_entries_to_write(
      importerexporter.entries.uniq(&:identifier).select { |e| valid_entry_types.include?(e.type) }
    )

    entries_to_write[0..limit || total].in_groups_of(records_split_count, false) do |group|
      folder_count += 1

      CSV.open(setup_export_file(folder_count), "w", headers: export_headers, write_headers: true) do |csv|
        group.each do |entry|
          csv << entry.parsed_metadata
          next if importerexporter.metadata_only? || entry.type == 'Bulkrax::CsvCollectionEntry'

          store_files(entry.identifier, folder_count.to_s)
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def store_files(identifier, folder_count)
    record = ActiveFedora::Base.find(identifier)
    return unless record

    file_sets = pull_export_filesets(record)
    file_sets << record.thumbnail if exporter.include_thumbnails && record.thumbnail.present? && record.work?
    process_multiple_file_export(file_sets, folder_count)
  rescue Ldp::Gone
    nil
  end

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

    ::AssociateFilesetsWithWorkJob.perform_later(importer)
    importer.last_run.parents.each do |parent_id|
      ::Bulkrax::CreateRelationshipsJob.perform_later(parent_identifier: parent_id, importer_run_id: importer.last_run.id)
    end
  end
end

Bulkrax::ExportBehavior.module_eval do
  def filename(file_set)
    uploader_types = ['service_file', 'preservation_master_file', 'intermediate_file',
                      'extracted', 'transcript_file']
    working_array = []
    uploader_types.each do |type|
      begin
        file = file_set.send(type)
      rescue
        file = nil
      end
      working_array << "#{file.file_name.first}:#{type}" if file.present?
    end

    working_array.compact.join('|')
  end
end

Bulkrax::Exporter.class_eval do
  delegate :write, :create_from_collection, :create_from_object_ids, :create_from_importer, :create_from_worktype, :create_from_all, to: :parser

  def export
    current_run && setup_export_path
    case export_from
    when 'collection'
      create_from_collection
    when 'object_ids'
      create_from_object_ids
    when 'importer'
      create_from_importer
    when 'worktype'
      create_from_worktype
    when 'all'
      create_from_all
    end
  rescue StandardError => e
    status_info(e)
  end

  def export_source_object_ids
    export_source if export_from == 'object_ids'
  end

  def export_from_list
    [
      [I18n.t('bulkrax.exporter.labels.importer'), 'importer'],
      [I18n.t('bulkrax.exporter.labels.collection'), 'collection'],
      ['Object IDs', 'object_ids'],
      [I18n.t('bulkrax.exporter.labels.worktype'), 'worktype'],
      [I18n.t('bulkrax.exporter.labels.all'), 'all']
    ]
  end
end
