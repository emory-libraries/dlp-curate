# frozen_string_literal: true

Bulkrax.setup do |config|
  # Add local parsers
  # config.parsers += [
  #   { name: 'MODS - My Local MODS parser', class_name: 'Bulkrax::ModsXmlParser', partial: 'mods_fields' },
  # ]

  # WorkType to use as the default if none is specified in the import
  # Default is the first returned by Hyrax.config.curation_concerns, stringified
  config.default_work_type = 'FileSet'

  # Factory Class to use when generating and saving objects
  config.object_factory = if Hyrax.config.valkyrie_transition?
                            Bulkrax::ValkyrieObjectFactory
                          else
                            Bulkrax::ObjectFactory
                          end

  # Path to store pending imports
  # config.import_path = 'tmp/imports'

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
      "administrative_unit" => { from: ["administrative_unit"], join: '|', parsed: true },
      "author_notes" => { from: ["author_notes"], join: '|' },
      "conference_dates" => { from: ["conference_dates"], join: '|' },
      "conference_name" => { from: ["conference_name"], join: '|' },
      "contact_information" => { from: ["contact_information"], join: '|' },
      "content_genres" => { from: ["content_genres"], split: '\|', join: '|' },
      "content_type" => { from: ["content_type"], join: '|', parsed: true },
      "contributors" => { from: ["contributors"], split: '\|', join: '|' },
      "copyright_date" => { from: ["copyright_date"], join: '|' },
      "creator" => { from: ["creator"], split: '\|', join: '|' },
      "data_classifications" => { from: ["data_classifications"], parsed: true, split: '\|', join: '|' },
      "data_collection_dates" => { from: ["data_collection_dates"], split: '\|', join: '|' },
      "data_producers" => { from: ["data_producers"], split: '\|', join: '|' },
      "data_source_notes" => { from: ["data_source_notes"], split: '\|', join: '|' },
      "date_created" => { from: ["date_created"], join: '|' },
      "date_digitized" => { from: ["date_digitized"], join: '|' },
      "date_issued" => { from: ["date_issued"], join: '|' },
      "deduplication_key" => { from: ["deduplication_key"], join: '|', source_identifier: true, search_field: 'deduplication_key_tesim' },
      "edition" => { from: ["edition"], join: '|' },
      "emory_ark" => { from: ["emory_ark"], split: '\|', join: '|' },
      "emory_rights_statements" => { from: ["emory_rights_statements"], split: '\|', join: '|' },
      "extent" => { from: ["extent"], join: '|' },
      "file" => { from: ["file"], split: '\;', join: ';' },
      "file_types" => { from: ["file_types"], split: '\|', join: '|' },
      "final_published_versions" => { from: ["final_published_versions"], split: '\|', join: '|' },
      "geographic_unit" => { from: ["geographic_unit"], join: '|' },
      "grant_agencies" => { from: ["grant_agencies"], split: '\|', join: '|' },
      "grant_information" => { from: ["grant_information"], split: '\|', join: '|' },
      "holding_repository" => { from: ["holding_repository"], join: '|' },
      "institution" => { from: ["institution"], join: '|' },
      "internal_rights_note" => { from: ["internal_rights_note"], join: '|' },
      "isbn" => { from: ["isbn"], join: '|' },
      "issn" => { from: ["issn"], join: '|' },
      "issue" => { from: ["issue"], join: '|' },
      "keywords" => { from: ["keywords"], split: '\|', join: '|' },
      "legacy_rights" => { from: ["legacy_rights"], join: '|' },
      "local_call_number" => { from: ["local_call_number"], join: '|' },
      "model" => { from: ["model"], join: '|' },
      "notes" => { from: ["notes"], split: '\|', join: '|' },
      "other_identifiers" => { from: ["other_identifiers"], split: '\|', join: '|' },
      "page_range_end" => { from: ["page_range_end"], join: '|' },
      "page_range_start" => { from: ["page_range_start"], join: '|' },
      "parent" => { from: ["parent"], related_parents_field_mapping: true },
      "parent_title" => { from: ["parent_title"], join: '|' },
      "pcdm_use" => { from: ["pcdm_use"], join: '|', parsed: true },
      "place_of_production" => { from: ["place_of_production"], join: '|' },
      "primary_language" => { from: ["primary_language"], join: '|' },
      "primary_repository_ID" => { from: ["primary_repository_ID"], join: '|' },
      "publisher" => { from: ["publisher"], join: '|' },
      "publisher_version" => { from: ["publisher_version"], join: '|', parsed: true },
      "re_use_license" => { from: ["re_use_license"], join: '|', parsed: true },
      "related_datasets" => { from: ["related_datasets"], split: '\|', join: '|' },
      "related_material_notes" => { from: ["related_material_notes"], split: '\|', join: '|' },
      "related_publications" => { from: ["related_publications"], split: '\|', join: '|' },
      "rights_documentation" => { from: ["rights_documentation"], join: '|' },
      "rights_holders" => { from: ["rights_holders"], split: '\|', join: '|' },
      "rights_statement" => { from: ["rights_statement"], split: '\|', join: '|', parsed: true },
      "scheduled_rights_review" => { from: ["scheduled_rights_review"], join: '|' },
      "scheduled_rights_review_note" => { from: ["scheduled_rights_review_note"], join: '|' },
      "sensitive_material" => { from: ["sensitive_material"], join: '|', parsed: true },
      "sensitive_material_note" => { from: ["sensitive_material_note"], join: '|' },
      "series_title" => { from: ["series_title"], join: '|' },
      "source_collection_id" => { from: ["source_collection_id"], join: '|' },
      "sponsor" => { from: ["sponsor"], join: '|' },
      "staff_notes" => { from: ["staff_notes"], split: '\|', join: '|' },
      "subject_geo" => { from: ["subject_geo"], split: '\|', join: '|' },
      "subject_names" => { from: ["subject_names"], split: '\|', join: '|' },
      "subject_time_periods" => { from: ["subject_time_periods"], split: '\|', join: '|' },
      "subject_topics" => { from: ["subject_topics"], split: '\|', join: '|' },
      "sublocation" => { from: ["sublocation"], join: '|' },
      "system_of_record_ID" => { from: ["system_of_record_ID"], join: '|' },
      "table_of_contents" => { from: ["table_of_contents"], join: '|' },
      "technical_note" => { from: ["technical_note"], join: '|' },
      "title" => { from: ["title"], parsed: true, split: '\|', join: '|' },
      "transfer_engineer" => { from: ["transfer_engineer"], join: '|' },
      "uniform_title" => { from: ["uniform_title"], join: '|' },
      "visibility" => { from: ["visibility"], join: '|', parsed: true },
      "volume" => { from: ["volume"], join: '|' }
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

Rails.application.reloader.to_prepare do
  # Sidebar for hyrax 3+ support
  if Object.const_defined?(:Hyrax) && ::Hyrax::DashboardController&.respond_to?(:sidebar_partials)
    Hyrax::DashboardController.sidebar_partials[:repository_content] << "hyrax/dashboard/sidebar/bulkrax_sidebar_additions"
  end

  # Below are all of the Bulkrax v8.2.3 overrides.
  require_relative '../../lib/bulkrax/override_assistive_methods'

  # AF-only ObjectFactory overrides (skipped in Valkyrie transition mode)
  unless Hyrax.config.valkyrie_transition?
    # rubocop:disable Metrics/BlockLength
    # rubocop:disable Lint/UselessAssignment
    Bulkrax::ObjectFactory.class_eval do
      include OverrideAssistiveMethods
      attr_reader(:attributes, :object, :source_identifier_value, :klass, :replace_files, :update_files,
                  :work_identifier, :related_parents_parsed_mapping, :importer_run_id, :parser, :user,
                  :work_identifier_search_field)

      transformation_removes_blank_hash_values = true

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

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        attributes:,
        source_identifier_value:,
        work_identifier:,
        work_identifier_search_field:,
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
        @work_identifier_search_field = work_identifier_search_field
        @related_parents_parsed_mapping = related_parents_parsed_mapping
        @source_identifier_value = source_identifier_value
        @klass = klass || Bulkrax.default_work_type.constantize
        @importer_run_id = importer_run_id
        @parser = parser
      end
      # rubocop:enable Metrics/ParameterLists

      def import_file(path)
        u = Hyrax::UploadedFile.new
        u.user_id = @user.id
        u.send("#{process_file_types(path.split('/').last)}=", CarrierWave::SanitizedFile.new(path))
        update_filesets(u)
      end
    end
    # rubocop:enable Lint/UselessAssignment
    # rubocop:enable Metrics/BlockLength
  end

  # Valkyrie-aware ValkyrieObjectFactory overrides (only in transition mode)
  if Hyrax.config.valkyrie_transition?
    # rubocop:disable Metrics/BlockLength
    Bulkrax::ValkyrieObjectFactory.class_eval do
      include PreservationEvents

      attr_reader :parser

      # Override initialize to accept parser: kwarg (Emory addition)
      # rubocop:disable Metrics/ParameterLists
      def initialize(attributes:, source_identifier_value:, work_identifier:, work_identifier_search_field:,
                     parser: nil, related_parents_parsed_mapping: nil, replace_files: false,
                     user: nil, klass: nil, importer_run_id: nil, update_files: false)
        @parser = parser
        super(attributes:, source_identifier_value:, work_identifier:,
              work_identifier_search_field:, related_parents_parsed_mapping:,
              replace_files:, user:, klass:, importer_run_id:, update_files:)
      end
      # rubocop:enable Metrics/ParameterLists

      # Fix typo in gem (custom_query -> custom_queries) and use search_field instead of name_field.
      # rubocop:disable Metrics/ParameterLists
      def self.search_by_property(value:, klass:, field: nil, search_field: nil, **)
        search_field ||= field
        raise "Expected search_field or field got nil" if search_field.blank?
        return if value.blank?

        Hyrax.query_service.custom_queries.find_by_model_and_property_value(model: klass, property: search_field, value:)
      end
      # rubocop:enable Metrics/ParameterLists

      def self.add_child_to_parent_work(parent:, child:)
        return true if parent.member_ids.include?(child.id)

        parent.member_ids += Array(child.id)
        parent.save
      end

      def self.add_resource_to_collection(collection:, resource:, user:)
        resource.member_of_collection_ids += Array(collection.id)
        save!(resource:, user:)
      end

      def create_work(attrs)
        event_start = DateTime.current
        attrs = HashWithIndifferentAccess.new(attrs)
        perform_transaction_for(object:, attrs:) do
          uploaded_files, file_set_params = prep_fileset_content(attrs)
          transactions["change_set.create_work"]
            .with_step_args(
              'work_resource.add_file_sets' => { uploaded_files:, file_set_params: },
              "change_set.set_user_as_depositor" => { user: @user },
              "work_resource.change_depositor" => { user: @user },
              'work_resource.save_acl' => { permissions_params: [attrs.try('visibility') || 'open'].compact }
            )
        end

        process_work_creation_preservation_events(event_start)
      end

      def update_work(attrs)
        event_start = DateTime.current
        attrs = HashWithIndifferentAccess.new(attrs)
        perform_transaction_for(object:, attrs:) do
          uploaded_files, file_set_params = prep_fileset_content(attrs)
          transactions["change_set.update_work"]
            .with_step_args(
              'work_resource.add_file_sets' => { uploaded_files:, file_set_params: },
              'work_resource.save_acl' => { permissions_params: [attrs.try('visibility') || 'open'].compact }
            )
        end

        pulled_work = pull_work_for_preservation_events
        create_preservation_event(pulled_work, work_update(event_start:, user_email: @user.email))
      end

      private

        def pull_work_for_preservation_events
          Hyrax.query_service.custom_queries.find_by_model_and_property_value(
            model:    CurateGenericWorkResource,
            property: 'deduplication_key_tesim',
            value:    attributes['deduplication_key']
          )
        end

        def process_work_creation_preservation_events(event_start)
          pulled_work = pull_work_for_preservation_events
          return unless pulled_work

          create_preservation_event(pulled_work, work_creation(event_start:, user_email: @user.email))
          create_preservation_event(pulled_work, work_policy(event_start:, visibility: pulled_work.visibility, user_email: @user.email))
        end
    end
    # rubocop:enable Metrics/BlockLength
  end

  Bulkrax::CsvEntry.class_eval do
    include OverrideAssistiveMethods

    def build_export_metadata
      self.parsed_metadata = {}

      build_system_metadata
      build_files_metadata if Bulkrax.collection_model_class.present? && !hyrax_record.is_a?(Bulkrax.collection_model_class)
      build_relationship_metadata
      build_mapping_metadata
      build_preservation_workflow_metadata if hyrax_record.is_a?(CurateGenericWork) || hyrax_record.is_a?(CurateGenericWorkResource)
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
        filenames_with_types = map_file_sets(file_sets) # Call of Emory-altered `#map_file_sets`, returns filenames with types.
        # The rest of this altered method allows us to use multiple file types.
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

        handle_join_on_export(relationship_key, values, '|') # Emory Alteration: we hardcode the join with pipes here.
      end
    end

    def build_value(property_name, mapping_config)
      return unless hyrax_record.respond_to?(property_name.to_s)

      data = hyrax_record.send(property_name.to_s)

      if property_name == 'visibility' # Emory Addition
        parsed_metadata[key_for_export(property_name)] = Bulkrax::CsvMatcher::VISIBILITY_MAPPING.key(data).titleize
      elsif mapping_config['join'] || !data.is_a?(Enumerable)
        # Emory Replacement: we use our own method with our altered logic instead of Bulkrax' `#prepare_export_data_with_join`.
        triples_values_joined(property_name, mapping_config, data)
      else
        data.each_with_index do |d, i|
          parsed_metadata["#{key_for_export(property_name)}_#{i + 1}"] = prepare_export_data(d)
        end
      end
    end

    def handle_join_on_export(key, values, join)
      if join
        # Emory Alteration: we pass along the actual `join` character instead of `true`/`false`, and use it below.
        parsed_metadata[key] = values.join(join)
      else
        values.each_with_index do |value, i|
          parsed_metadata["#{key}_#{i + 1}"] = value
        end
        parsed_metadata.delete(key)
      end
    end
  end

  Bulkrax::ApplicationParser.class_eval do
    def create_entry_and_job(current_record, type, identifier = nil)
      identifier ||= current_record[source_identifier]&.strip # Emory Alteration; adds the `#strip` to the value.
      new_entry = find_or_create_entry(send("#{type}_entry_class"),
                                       identifier,
                                       'Bulkrax::Importer',
                                       record_raw_metadata(current_record))
      new_entry.status_info('Pending', importer.current_run)
      if record_deleted?(current_record)
        "Bulkrax::Delete#{type.camelize}Job".constantize.send(perform_method, new_entry, current_run)
      elsif record_remove_and_rerun?(current_record) || remove_and_rerun
        delay = calculate_type_delay(type)
        "Bulkrax::DeleteAndImport#{type.camelize}Job".constantize.set(wait: delay).send(perform_method, new_entry, current_run)
      else
        "Bulkrax::Import#{type.camelize}Job".constantize.send(perform_method, new_entry.id, current_run.id)
      end
    end
  end

  Bulkrax::ParserExportRecordSet.module_eval do
    class ObjectId < Bulkrax::ParserExportRecordSet::Base
      def current_record_objects
        @current_record_objects ||=
          begin
            object_ids = importerexporter.export_source.split('|')

            object_ids&.map { |id| Hyrax::SolrService.query("id:#{id}") }&.flatten&.compact
          end
      end

      def works
        @works ||= current_record_objects.select { |object| object['has_model_ssim'].first == 'CurateGenericWork' }
      end

      def collections
        @collections ||= current_record_objects.select { |object| object['has_model_ssim'].first == 'Collection' }
      end
    end
  end

  Bulkrax::CsvParser.class_eval do
    include OverrideAssistiveMethods
    alias create_from_object_ids create_new_entries

    # Bulkrax v8.2.3 override: swaps out Bulkrax' sorting for our own, grouping together
    #   CurateGenericWorks with their associated FileSets.
    # rubocop:disable Metrics/MethodLength
    def write_files
      require 'open-uri'
      folder_count = 0
      # TODO: This is not performant as well; unclear how to address, but lower priority as of
      #       <2023-02-21 Tue>.
      entries_to_write = sort_entries_to_write(
        importerexporter.entries.uniq(&:identifier).select { |e| valid_entry_types.include?(e.type) }
      )

      group_size = limit.to_i.zero? ? total : limit.to_i
      entries_to_write[0..group_size].in_groups_of(records_split_count, false) do |group|
        folder_count += 1

        CSV.open(setup_export_file(folder_count), "w", headers: export_headers, write_headers: true) do |csv|
          group.each do |entry|
            csv << entry.parsed_metadata
            # TODO: This is precarious when we have descendents of Bulkrax::CsvCollectionEntry
            next if importerexporter.metadata_only? || entry.type == 'Bulkrax::CsvCollectionEntry'

            store_files(entry.identifier, folder_count.to_s)
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def store_files(identifier, folder_count)
      record = Bulkrax.object_factory.find(identifier)
      return unless record

      file_sets = pull_export_filesets(record)
      file_sets << record.thumbnail if exporter.include_thumbnails && record.thumbnail.present? && record.work?
      process_multiple_file_export(file_sets, folder_count)
    rescue Ldp::Gone
      nil
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
        Bulkrax.relationship_job_class.constantize.perform_later(parent_identifier: parent_id,
                                                                 importer_run_id:   importer.last_run.id)
      end
    end
  end

  Bulkrax::ImportBehavior.module_eval do
    def factory
      of = Bulkrax.object_factory || Bulkrax::ObjectFactory
      @factory ||= of.new(
        attributes:                     parsed_metadata,
        source_identifier_value:        identifier,
        work_identifier:                parser.work_identifier,
        work_identifier_search_field:   parser.work_identifier_search_field,
        related_parents_parsed_mapping: parser.related_parents_parsed_mapping,
        replace_files:,
        user:,
        klass:                          factory_class,
        importer_run_id:                importerexporter.last_run.id,
        update_files:,
        parser: # Emory addition
      )
    end
  end

  Bulkrax::ExportBehavior.module_eval do
    def filename(file_set)
      if file_set.is_a?(Hyrax::Resource)
        filename_valkyrie(file_set)
      else
        filename_af(file_set)
      end
    end

    def filename_af(file_set)
      uploader_types = ['service_file', 'preservation_master_file', 'intermediate_file',
                        'extracted', 'transcript_file']
      working_array = []
      uploader_types.each do |type|
        begin
          file = file_set.send(type)
        rescue
          file = nil
        end
        next if file.blank?

        file_name = file.respond_to?(:original_filename) ? file.original_filename : file.file_name.first

        working_array << "#{file_name}:extracted_text" if type == 'extracted'
        working_array << "#{file_name}:transcript" if type == 'transcript_file'
        working_array << "#{file_name}:#{type}" unless type == 'extracted' || type == 'transcript_file'
      end
      working_array.compact.join('|')
    end

    def filename_valkyrie(file_set)
      file_metadatas = Hyrax.custom_queries.find_files(file_set:)
      working_array = []
      file_metadatas.each do |fm|
        file_name = Array(fm.original_filename).first || fm.label.to_s
        next if file_name.blank?

        type = valkyrie_file_use_label(fm)
        working_array << "#{file_name}:#{type}"
      end
      working_array.compact.join('|')
    end

    def valkyrie_file_use_label(file_metadata)
      use = Array(file_metadata.pcdm_use).first || Array(file_metadata.type).first.to_s
      case use.to_s
      when /ExtractedText/, /extracted/i
        'extracted_text'
      when /Transcript/, /transcript/i
        'transcript'
      when /ServiceFile/, /service/i
        'service_file'
      when /IntermediateFile/, /intermediate/i
        'intermediate_file'
      else
        'preservation_master_file'
      end
    end
  end

  Bulkrax::Exporter.class_eval do
    delegate :write, :create_from_collection, :create_from_object_ids, :create_from_importer, :create_from_worktype, :create_from_all, to: :parser

    # Emory Addition: create our own export_source rule for object_ids
    def export_source_object_ids
      export_source if export_from == 'object_ids'
    end

    def export_from_list
      if defined?(::Hyrax)
        [
          [I18n.t('bulkrax.exporter.labels.importer'), 'importer'],
          [I18n.t('bulkrax.exporter.labels.collection'), 'collection'],
          ['Object IDs', 'object_ids'],
          [I18n.t('bulkrax.exporter.labels.worktype'), 'worktype'],
          [I18n.t('bulkrax.exporter.labels.all'), 'all']
        ]
      else
        [
          [I18n.t('bulkrax.exporter.labels.importer'), 'importer'],
          [I18n.t('bulkrax.exporter.labels.collection'), 'collection'],
          ['Object IDs', 'object_ids'],
          [I18n.t('bulkrax.exporter.labels.all'), 'all']
        ]
      end
    end
  end

  Bulkrax::DatatablesBehavior.module_eval do
    # rubocop:disable Metrics/PerceivedComplexity
    def format_importers(importers)
      result = importers.map do |i|
        {
          name:                     view_context.link_to(i.name, view_context.importer_path(i)),
          status_message:           status_message_for(i),
          last_imported_at:         i.last_imported_at&.strftime("%F %T"), # only altered time format
          next_import_at:           i.next_import_at&.strftime("%F %T"), # only altered time format
          enqueued_records:         i.last_run&.enqueued_records,
          processed_records:        i.last_run&.processed_records || 0,
          failed_records:           i.last_run&.failed_records || 0,
          deleted_records:          i.last_run&.deleted_records,
          total_collection_entries: i.last_run&.total_collection_entries,
          total_work_entries:       i.last_run&.total_work_entries,
          total_file_set_entries:   i.last_run&.total_file_set_entries,
          actions:                  importer_util_links(i)
        }
      end
      {
        data:            result,
        recordsTotal:    Bulkrax::Importer.count,
        recordsFiltered: Bulkrax::Importer.count
      }
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def format_entries(entries, item)
      result = entries.map do |e|
        {
          identifier:     view_context.link_to(e.identifier, view_context.item_entry_path(item, e)),
          title:          e&.parsed_metadata&.[]('title'),
          id:             e.id,
          status_message: status_message_for(e),
          type:           e.type,
          updated_at:     e.updated_at,
          errors:         e.status_message == 'Failed' ? view_context.link_to(e.error_class, view_context.item_entry_path(item, e)) : "",
          curate_obj:     curate_obj_text(e),
          actions:        entry_util_links(e, item)
        }
      end
      {
        data:            result,
        recordsTotal:    item.entries.size,
        recordsFiltered: item.entries.size
      }
    end

    def curate_obj_text(entry)
      obj = entry.importerexporter_type == "Bulkrax::Exporter" ? entry&.hyrax_record : entry&.factory&.find
      text_array = []
      link = if defined?(Hyrax) && entry.factory_class.model_name.human == 'Collection'
               hyrax.polymorphic_path(obj)
             else
               main_app.polymorphic_path(obj)
             end

      text_array << view_context.link_to(view_context.raw('<span class="fa fa-solid fa-link"></span>'), link) if obj.present?
      text_array.join(" ")
    end
  end
end
