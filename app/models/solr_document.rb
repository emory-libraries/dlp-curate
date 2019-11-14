# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Gallery::OpenseadragonSolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior

  # self.unique_key = 'id'
  def preservation_workflow_terms
    self[Solrizer.solr_name('preservation_workflow_terms')]
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
end
