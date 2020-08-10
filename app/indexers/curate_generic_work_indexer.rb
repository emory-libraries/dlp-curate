# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work CurateGenericWork`
class CurateGenericWorkIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  # include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  # include Hyrax::IndexesLinkedMetadata

  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['preservation_workflow_terms_tesim'] = preservation_workflow_terms
      solr_doc['failed_preservation_events_ssim'] = [failed_preservation_events]
      solr_doc['preservation_event_tesim'] = [object&.preservation_event&.map(&:preservation_event_terms)]
      solr_doc['human_readable_content_type_ssim'] = [human_readable_content_type]
      solr_doc['human_readable_rights_statement_ssim'] = [human_readable_rights_statement]
      solr_doc['human_readable_re_use_license_ssim'] = [human_readable_re_use_license]
      solr_doc['year_created_isim'] = year_created
      solr_doc['human_readable_date_created_tesim'] = [human_readable_date_created]
      solr_doc['human_readable_date_issued_tesim'] = [human_readable_date_issued]
      solr_doc['year_issued_isim'] = year_issued
      solr_doc['year_for_lux_isim'] = year_for_lux
      solr_doc['human_readable_data_collection_dates_tesim'] = human_readable_data_collection_dates
      solr_doc['human_readable_conference_dates_tesim'] = [human_readable_conference_dates]
      solr_doc['human_readable_copyright_date_tesim'] = [human_readable_copyright_date]
      solr_doc['title_ssort'] = sort_title
      solr_doc['creator_ssort'] = object.creator.first
      solr_doc['year_for_lux_ssi'] = sort_year
      solr_doc['child_works_for_lux_tesim'] = child_works_for_lux
      solr_doc['parent_work_for_lux_tesim'] = parent_work_for_lux
      solr_doc['source_collection_title_ssim'] = source_collection
      # the next two fields are for display and search, not for security
      solr_doc['visibility_group_ssi'] = visibility_group_for_lux
      solr_doc['human_readable_visibility_ssi'] = human_readable_visibility
    end
  end

  def failed_preservation_events
    failures = object.preservation_event.select { |event| event.outcome == ["Failure"] }
    return if failures.blank?
    failures.map(&:failed_event_json)
  end

  def preservation_workflow_terms
    object.preservation_workflow.map(&:preservation_terms)
  end

  def human_readable_content_type
    return unless object.content_type
    FormatLabelService.instance.label(uri: object.content_type)
  end

  def human_readable_rights_statement
    return [] if object.rights_statement.empty?
    RightsStatementLabelService.instance.label(uri: object.rights_statement.first)
  end

  def human_readable_re_use_license
    return unless object.re_use_license
    LicensesLabelService.instance.label(uri: object.re_use_license)
  end

  def human_readable_date_created
    return unless object.date_created
    DateService.instance.human_readable_date(object.date_created)
  end

  def human_readable_date_issued
    return unless object.date_issued
    DateService.instance.human_readable_date(object.date_issued)
  end

  def human_readable_data_collection_dates
    return [] if object.data_collection_dates.empty?
    object.data_collection_dates.map { |date| DateService.instance.human_readable_date(date) }
  end

  def human_readable_conference_dates
    return unless object.conference_dates
    DateService.instance.human_readable_date(object.conference_dates)
  end

  def human_readable_copyright_date
    return unless object.copyright_date
    DateService.instance.human_readable_date(object.copyright_date)
  end

  def year_created
    integer_years = YearParser.integer_years(object.date_created)
    return nil if integer_years.blank?
    integer_years
  end

  def year_issued
    integer_years = YearParser.integer_years(object.date_issued)
    return nil if integer_years.blank?
    integer_years
  end

  def year_for_lux
    years = [year_created, year_issued].flatten.compact.uniq.sort
    return nil if years.empty?
    years
  end

  def sort_title
    return unless object.title.first
    object.title.first.gsub(/^(an?|the)\s/i, '')
  end

  def sort_year
    year_for_lux.nil? ? nil : year_for_lux.first
  end

  def child_works_for_lux
    children = object.child_works.sort_by { |c| c.title.first }
    return nil if children.empty?
    children.map do |c|
      id = c.id
      title = c.title.first
      thumbnail_path = c.to_solr["thumbnail_path_ss"]
      "#{id}, #{thumbnail_path}, #{title}"
    end
  end

  def parent_work_for_lux
    parent = object.parent_works.first
    return nil if parent.nil?
    id = parent.id
    title = parent.title.first
    ["#{id}, #{title}"]
  end

  # This field is for display and search, not to determine security
  def visibility_group_for_lux
    case object.visibility
    when "open", "low_res"
      "Public"
    when "emory_low", "authenticated"
      "Log In Required"
    when "rose_high"
      "Reading Room Only"
    end
  end

  # This field is for display and search, not to determine security
  def human_readable_visibility
    case object.visibility
    when "open"
      "Public"
    when "low_res"
      "Public Low View"
    when "emory_low"
      "Emory Low Download"
    when "authenticated"
      "Emory High Download"
    when "rose_high"
      "Rose High View"
    when "restricted"
      "Private"
    end
  end

  def source_collection
    collection = Collection.find(object.source_collection_id) if object.source_collection_id
    return collection.title unless collection.nil?
  end
end
