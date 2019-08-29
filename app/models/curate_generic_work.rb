# frozen_string_literal: true
class CurateGenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  self.indexer = CurateGenericWorkIndexer

  def assign_id
    service.mint
  end

  validates :title, presence: { message: 'Your work must have a title.' }
  validates :final_published_version, url: true, if: -> { final_published_version.present? }
  validates :related_publications, url: true, if: -> { related_publications.present? }
  validates :related_datasets, url: true, if: -> { related_datasets.present? }
  validates :rights_documentation, url: true, if: -> { rights_documentation.present? }

  property :abstract, predicate: "http://purl.org/dc/elements/1.1/description", multiple: false do |index|
    index.as :stored_searchable
  end

  property :access_right, predicate: "http://purl.org/dc/terms/accessRights" do |index|
    index.as :stored_searchable
  end

  property :administrative_unit, predicate: "http://id.loc.gov/vocabulary/relators/cur", multiple: false do |index|
    index.as :stored_searchable
  end

  property :author_notes, predicate: "http://metadata.emory.edu/vocab/cor-terms#authorNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :conference_dates, predicate: "http://rdaregistry.info/Elements/u/P60526", multiple: false

  property :conference_name, predicate: "http://purl.org/dc/terms/relation#conferenceOrMeeting", multiple: false do |index|
    index.as :stored_searchable
  end

  property :contact_information, predicate: "http://www.rdaregistry.info/Elements/u/#P60490", multiple: false do |index|
    index.as :stored_searchable
  end

  property :content_genre, predicate: "http://www.europeana.edu/schemas/edm/hasType" do |index|
    index.as :stored_searchable, :facetable
  end

  property :content_type, predicate: "http://purl.org/dc/terms/type", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :contributor, predicate: "http://purl.org/dc/elements/1.1/contributor" do |index|
    index.as :stored_searchable
  end

  property :copyright_date, predicate: "http://purl.org/dc/terms/dateCopyrighted", multiple: false do |index|
    index.as :stored_searchable
  end

  property :creator, predicate: "http://purl.org/dc/elements/1.1/creator" do |index|
    index.as :stored_searchable, :facetable
  end

  property :data_classification, predicate: "http://metadata.emory.edu/vocab/cor-terms#dataClassification" do |index|
    index.as :stored_searchable
  end

  property :data_collection_dates, predicate: "http://metadata.emory.edu/vocab/cor-terms#dataCollectionDates" do |index|
    index.as :stored_searchable
  end

  property :data_producer, predicate: "http://id.loc.gov/vocabulary/relators/prv" do |index|
    index.as :stored_searchable
  end

  property :data_source_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#dataSourcesNote" do |index|
    index.as :stored_searchable
  end

  property :date_created, predicate: "http://purl.org/dc/terms/created", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :date_digitized, predicate: "http://metadata.emory.edu/vocab/cor-terms#dateDigitized", multiple: false do |index|
    index.as :stored_searchable
  end

  property :date_issued, predicate: "http://purl.org/dc/terms/issued", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :edition, predicate: "http://id.loc.gov/ontologies/bibframe/editionStatement", multiple: false

  property :extent, predicate: "http://www.rdaregistry.info/Elements/u/#P60550", multiple: false do |index|
    index.as :stored_searchable
  end

  property :final_published_version, predicate: "http://purl.org/dc/terms/hasVersion"

  property :geographic_unit, predicate: "http://metadata.emory.edu/vocab/cor-terms#geographicUnit", multiple: false do |index|
    index.as :stored_searchable
  end

  property :grant, predicate: "http://id.loc.gov/vocabulary/relators/fnd" do |index|
    index.as :stored_searchable
  end

  property :grant_information, predicate: "http://metadata.emory.edu/vocab/cor-terms#grantOrFundingNote"

  property :holding_repository, predicate: "http://id.loc.gov/vocabulary/relators/rps", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :institution, predicate: "http://rdaregistry.info/Elements/u/P60402", multiple: false do |index|
    index.as :stored_searchable
  end

  property :internal_rights_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#internalRightsNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :isbn, predicate: "http://id.loc.gov/vocabulary/identifiers/isbn", multiple: false do |index|
    index.as :stored_searchable
  end

  property :issn, predicate: "http://id.loc.gov/vocabulary/identifiers/issn", multiple: false do |index|
    index.as :stored_searchable
  end

  property :issue, predicate: "http://purl.org/ontology/bibo/issue", multiple: false

  property :keywords, predicate: "http://schema.org/keywords" do |index|
    index.as :stored_searchable
  end

  property :legacy_ark, predicate: "http://id.loc.gov/vocabulary/identifiers/local#ark" do |index|
    index.as :stored_searchable
  end

  property :legacy_identifier, predicate: "http://id.loc.gov/vocabulary/identifiers/local#legacy" do |index|
    index.as :stored_searchable
  end

  property :legacy_rights, predicate: "http://metadata.emory.edu/vocab/cor-terms#legacyRights", multiple: false do |index|
    index.as :stored_searchable
  end

  property :local_call_number, predicate: "http://metadata.emory.edu/vocab/cor-terms#localCallNumber", multiple: false do |index|
    index.as :stored_searchable
  end

  property :note, predicate: "http://www.w3.org/2004/02/skos/core#note" do |index|
    index.as :stored_searchable
  end

  property :page_range_end, predicate: "http://purl.org/ontology/bibo/pageEnd", multiple: false

  property :page_range_start, predicate: "http://purl.org/ontology/bibo/pageStart", multiple: false

  property :parent_title, predicate: "http://rdaregistry.info/Elements/u/P60101", multiple: false do |index|
    index.as :stored_searchable
  end

  property :place_of_production, predicate: "http://id.loc.gov/vocabulary/relators/pup", multiple: false

  property :preservation_workflow, predicate: "http://metadata.emory.edu/vocab/cor-terms#preservation_workflow", class_name: "PreservationWorkflow"

  property :primary_language, predicate: "http://purl.org/dc/elements/1.1/language", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :primary_repository_ID, predicate: "http://purl.org/dc/terms/identifier", multiple: false do |index|
    index.as :stored_searchable
  end

  property :publisher, predicate: "http://purl.org/dc/elements/1.1/publisher", multiple: false do |index|
    index.as :stored_searchable
  end

  property :publisher_version, predicate: "http://metadata.emory.edu/vocab/cor-terms#publicationStage", multiple: false do |index|
    index.as :stored_searchable
  end

  property :re_use_license, predicate: "http://schema.org/license", multiple: false

  property :related_datasets, predicate: "http://purl.org/dc/terms/relation#dataset"

  property :related_material, predicate: "http://purl.org/dc/elements/1.1/relation" do |index|
    index.as :stored_searchable
  end

  property :related_publications, predicate: "http://purl.org/dc/terms/relation#publication"

  property :rights_documentation, predicate: "http://metadata.emory.edu/vocab/cor-terms#rightsDocumentationURI", multiple: false

  property :rights_holder, predicate: "http://purl.org/dc/terms/rightsHolder"

  property :rights_statement, predicate: "http://www.europeana.eu/schemas/edm/rights" do |index|
    index.as :stored_searchable, :facetable
  end

  property :rights_statement_text, predicate: "http://purl.org/dc/elements/1.1/rights" do |index|
    index.as :stored_searchable
  end

  property :scheduled_rights_review, predicate: "http://metadata.emory.edu/vocab/cor-terms#scheduledRightsReview", multiple: false do |index|
    index.as :stored_searchable
  end

  property :scheduled_rights_review_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#scheduledRightsReviewNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :sensitive_material, predicate: "http://metadata.emory.edu/vocab/cor-terms#sensitiveMaterial", multiple: false do |index|
    index.as :stored_searchable
  end

  property :sensitive_material_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#sensitiveMaterialNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :series_title, predicate: "http://id.loc.gov/ontologies/bibframe/seriesStatement", multiple: false do |index|
    index.as :stored_searchable
  end

  property :sponsor, predicate: "http://id.loc.gov/vocabulary/relators/spn", multiple: false

  property :staff_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#staffNote" do |index|
    index.as :stored_searchable
  end

  property :subject_geo, predicate: "http://purl.org/dc/elements/1.1/coverage" do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_names, predicate: "http://purl.org/dc/elements/1.1/subject#names" do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_time_periods, predicate: "http://schema.org/temporalCoverage" do |index|
    index.as :stored_searchable
  end

  property :subject_topics, predicate: "http://purl.org/dc/elements/1.1/subject" do |index|
    index.as :stored_searchable, :facetable
  end

  property :sublocation, predicate: "http://metadata.emory.edu/vocab/cor-terms#physicalSublocation", multiple: false do |index|
    index.as :stored_searchable
  end

  property :system_of_record_ID, predicate: "http://metadata.emory.edu/vocab/cor-terms#descriptiveSystemID", multiple: false do |index|
    index.as :stored_searchable
  end

  property :table_of_contents, predicate: "http://purl.org/dc/terms/tableOfContents", multiple: false do |index|
    index.as :stored_searchable
  end

  property :technical_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#technicalNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :transfer_engineer, predicate: "http://metadata.emory.edu/vocab/cor-terms#fileTransferEngineer", multiple: false do |index|
    index.as :stored_searchable
  end

  property :uniform_title, predicate: "http://purl.org/dc/elements/1.1/title", multiple: false do |index|
    index.as :stored_searchable
  end

  property :volume, predicate: "http://purl.org/ontology/bibo/volume", multiple: false

  # accepts_nested_attributes_for can not be called until all
  # the properties are declared because it calls resource_class,
  # which finalizes the propery declarations.
  # See https://github.com/projecthydra/active_fedora/issues/847
  accepts_nested_attributes_for :preservation_workflow, allow_destroy: true,
  reject_if: proc { |attrs|
    ['workflow_type', 'workflow_notes', 'workflow_rights_basis',
     'workflow_rights_basis_note', 'workflow_rights_basis_date',
     'workflow_rights_basis_reviewer', 'workflow_rights_basis_uri'].all? do |key|
       Array(attrs[key]).all?(&:blank?)
     end
  }

  private

    def service
      @service ||= Noid::Rails::Service.new
    end
end
