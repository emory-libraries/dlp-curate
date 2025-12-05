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
  config.object_factory = Bulkrax::ObjectFactory

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
end

Bulkrax::DatatablesBehavior.module_eval do
  def format_importers(importers)
    result = importers.map do |i|
      {
        name: view_context.link_to(i.name, view_context.importer_path(i)),
        status_message: status_message_for(i),
        last_imported_at: i.last_imported_at&.strftime("%F %T"),
        next_import_at: i.next_import_at&.strftime("%F %T"),
        enqueued_records: i.last_run&.enqueued_records,
        processed_records: i.last_run&.processed_records || 0,
        failed_records: i.last_run&.failed_records || 0,
        deleted_records: i.last_run&.deleted_records,
        total_collection_entries: i.last_run&.total_collection_entries,
        total_work_entries: i.last_run&.total_work_entries,
        total_file_set_entries: i.last_run&.total_file_set_entries,
        actions: importer_util_links(i)
      }
    end
    {
      data: result,
      recordsTotal: Bulkrax::Importer.count,
      recordsFiltered: Bulkrax::Importer.count
    }
  end
end
