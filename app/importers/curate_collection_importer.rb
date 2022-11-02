# frozen_string_literal: true
require 'csv'

# Deprecation Warning: As of Curate v3, Zizia will be removed. This is an artifact
#   of the Zizia install that will likely be removed.
class CurateCollectionImporter
  def initialize
    @library_collection_type_gid = Curate::CollectionType.find_or_create_library_collection_type.gid
  end

  def import(csv_file, log_location = STDOUT)
    CSV.foreach(csv_file, headers: true) do |row|
      collection_attrs = row.to_hash
      # If a Collection object with a given deduplication key-value pair already exists,
      # don't update the collection
      dedup_key = collection_attrs["deduplication_key"]
      dedup_value = collection_attrs[dedup_key]
      next if Collection.exists?(dedup_key => dedup_value)
      collection = Collection.new
      collection.visibility = "open"
      collection.local_call_number = collection_attrs["local_call_number"]
      collection.collection_type_gid = @library_collection_type_gid
      collection.title = multivalue_mapping(collection_attrs, "title")
      collection.institution = collection_attrs["institution"]
      collection.holding_repository = multivalue_mapping(collection_attrs, "holding_repository")
      collection.administrative_unit = multivalue_mapping(collection_attrs, "administrative_unit")
      collection.contact_information = collection_attrs["contact_information"]
      collection.abstract = collection_attrs["abstract"]
      collection.primary_language = collection_attrs["primary_language"]
      collection.keywords = multivalue_mapping(collection_attrs, "keywords")
      collection.subject_topics = multivalue_mapping(collection_attrs, "subject_topics")
      collection.subject_names = multivalue_mapping(collection_attrs, "subject_names")
      collection.subject_geo = multivalue_mapping(collection_attrs, "subject_geo")
      collection.subject_time_periods = multivalue_mapping(collection_attrs, "subject_time_periods")
      collection.creator = multivalue_mapping(collection_attrs, "creator")
      collection.contributors = multivalue_mapping(collection_attrs, "contributors")
      collection.notes = multivalue_mapping(collection_attrs, "notes")
      collection.rights_documentation = collection_attrs["rights_documentation"]
      collection.internal_rights_note = collection_attrs["internal_rights_note"]
      collection.sensitive_material = collection_attrs["sensitive_material"]
      collection.staff_notes = multivalue_mapping(collection_attrs, "staff_notes")
      collection.system_of_record_ID = collection_attrs["system_of_record_ID"]
      collection.emory_ark = multivalue_mapping(collection_attrs, "emory_ark")
      collection.primary_repository_ID = collection_attrs["primary_repository_ID"]
      collection.finding_aid_link = collection_attrs["finding_aid_link"]
      collection.save
      manage_groups = multivalue_mapping(collection_attrs, "manage")
      deposit_groups = multivalue_mapping(collection_attrs, "deposit")
      view_groups = multivalue_mapping(collection_attrs, "view")
      access_groups = { 'manage' => manage_groups, 'deposit' => deposit_groups, 'view' => view_groups }
      CollectionPermissionEnsurer.new(collection: collection, access_permissions: access_groups)
      @logger = Logger.new(log_location)
      @logger.level = Logger::DEBUG
      @logger.info "#{collection} collection object created"
    end
  end

  # Return an array of values. Use pipe (|) as the delimiter for values.
  # Strip any extra whitespace.
  def multivalue_mapping(collection_attrs, fieldname)
    return [] unless collection_attrs[fieldname]
    collection_attrs[fieldname].split("|").map(&:strip)
  end
end
