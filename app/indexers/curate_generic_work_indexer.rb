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
      solr_doc['preservation_workflow_terms_sim'] = preservation_workflow_terms
      solr_doc['human_readable_content_type_ssim'] = [human_readable_content_type]
      solr_doc['human_readable_rights_statement_ssim'] = [human_readable_rights_statement]
      solr_doc['human_readable_re_use_license_ssim'] = [human_readable_re_use_license]
      solr_doc['human_readable_date_created_ssim'] = [human_readable_date_created]
      solr_doc['human_readable_date_issued_ssim'] = [human_readable_date_issued]
      solr_doc['human_readable_data_collection_dates_ssim'] = human_readable_data_collection_dates
      solr_doc['human_readable_conference_dates_ssim'] = [human_readable_conference_dates]
      solr_doc['human_readable_copyright_date_ssim'] = [human_readable_copyright_date]
    end
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
end
