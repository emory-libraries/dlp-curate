# frozen_string_literal: true
require 'csv'

class CurateCollectionImporter
  def initialize
    @library_collection_type_gid = Curate::CollectionType.find_or_create_library_collection_type.gid
  end

  # If a Collection object with the specified call number already exists, return it
  # for updating. Otherwise, create a new Collection object.
  def check_for_existing_collection(local_call_number)
    existing_collection = Collection.where(local_call_number: local_call_number)&.first
    return existing_collection if existing_collection
    Collection.new
  end

  def import(csv_file)
    CSV.foreach(csv_file, headers: true) do |row|
      collection_attrs = row.to_hash
      local_call_number = collection_attrs["local_call_number"]
      collection = check_for_existing_collection(local_call_number)
      collection.visibility = "open"
      collection.local_call_number = local_call_number
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
      collection.contributor = multivalue_mapping(collection_attrs, "contributor")
      collection.note = multivalue_mapping(collection_attrs, "note")
      collection.rights_documentation = collection_attrs["rights_documentation"]
      collection.internal_rights_note = collection_attrs["internal_rights_note"]
      collection.sensitive_material = collection_attrs["sensitive_material"]
      collection.staff_note = multivalue_mapping(collection_attrs, "staff_note")
      collection.system_of_record_ID = collection_attrs["system_of_record_ID"]
      collection.legacy_ark = multivalue_mapping(collection_attrs, "legacy_ark")
      collection.primary_repository_ID = collection_attrs["primary_repository_ID"]
      collection.finding_aid_link = collection_attrs["finding_aid_link"]
      collection.save
      add_repository_administrators_as_managers(collection)
    end
  end

  def find_or_create_permission_template(collection)
    existing_hpt = Hyrax::PermissionTemplate.where(source_id: collection.id).try(:first)
    return existing_hpt if existing_hpt
    hpt = Hyrax::PermissionTemplate.new
    hpt.source_id = collection.id
    hpt.save
    hpt
  end

  def repo_admins_have_manage_rights?(hpt)
    existing_hpta = Hyrax::PermissionTemplateAccess.where(
      permission_template_id: hpt.id,
      agent_type: "group",
      agent_id: "Repository Administrators",
      access: "manage"
    ).count
    return true if existing_hpta.positive?
    false
  end

  def add_repository_administrators_as_managers(collection)
    hpt = find_or_create_permission_template(collection)
    return if repo_admins_have_manage_rights?(hpt)
    hpta = Hyrax::PermissionTemplateAccess.new
    hpta.permission_template_id = hpt.id
    hpta.agent_type = "group"
    hpta.agent_id = "Repository Administrators"
    hpta.access = "manage"
    hpta.save
  end

  # Return an array of values. Use pipe (|) as the delimiter for values.
  # Strip any extra whitespace.
  def multivalue_mapping(collection_attrs, fieldname)
    return [] unless collection_attrs[fieldname]
    collection_attrs[fieldname].split("|").map(&:strip)
  end
end
