# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior

  # removed Solrizer convention to be compliant with v3.0.0.pre.beta3
  # self.unique_key = 'id'
  def preservation_workflow_terms
    self['preservation_workflow_terms_tesim']
  end

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Do content negotiation for AF models.

  use_extension(Hydra::ContentNegotiation)
  include SolrDocumentAccessors

  def pcdm_use
    self['pcdm_use_tesim']
  end

  def failed_preservation_events
    self['failed_preservation_events_ssim']
  end

  def file_name
    self['file_name_ssim']
  end

  def file_path
    self['file_path_ssim']
  end

  def file_size
    self['file_size_ssim']
  end

  def created
    self['date_created_ssim']
  end

  def valid
    self['valid_ssim']
  end

  def well_formed
    self['well_formed_ssim']
  end

  def creating_application_name
    self['creating_application_name_ssim']
  end

  def puid
    self['puid_ssim']
  end

  def character_set
    self['character_set_ssim']
  end

  def byte_order
    self['byte_order_ssim']
  end

  def color_space
    self['color_space_ssim']
  end

  def compression
    self['compression_ssim']
  end

  def profile_name
    self['profile_name_ssim']
  end

  def profile_version
    self['profile_version_ssim']
  end

  def human_readable_content_type
    self['human_readable_content_type_tesim']
  end

  def human_readable_rights_statement
    self['human_readable_rights_statement_tesim']
  end

  def human_readable_re_use_license
    self['human_readable_re_use_license_tesim']
  end

  def human_readable_date_created
    self['human_readable_date_created_tesim']
  end

  def human_readable_date_issued
    self['human_readable_date_issued_tesim']
  end

  def human_readable_data_collection_dates
    self['human_readable_data_collection_dates_tesim']
  end

  def human_readable_conference_dates
    self['human_readable_conference_dates_tesim']
  end

  def human_readable_copyright_date
    self['human_readable_copyright_date_tesim']
  end

  def year_created
    self['year_created_isim']
  end

  def year_issued
    self['year_issued_isim']
  end

  def year_for_lux
    self['year_for_lux_isim']
  end

  def sort_title
    self['title_ssort']
  end

  def sort_creator
    self['creator_ssort']
  end

  def sort_year
    self['year_for_lux_ssi']
  end

  def child_works_for_lux
    self['child_works_for_lux_tesim']
  end

  def human_readable_visibility
    self['human_readable_visibility_ssi']
  end

  # Change below was necessary to institute Source/Deposit Collection structure.
  # For more information, read the SOURCE_DEPOSIT_CHANGES_README.md in dlp-curate's root folder.
  def source_collection_title
    self['source_collection_title_ssim']
  end
end
