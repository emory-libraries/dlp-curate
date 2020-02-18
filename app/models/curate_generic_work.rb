# frozen_string_literal: true
class CurateGenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include Identifier
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  self.indexer = CurateGenericWorkIndexer

  validates :title, presence: { message: 'Your work must have a title.' }
  validates :final_published_versions, url: true, if: -> { final_published_versions.present? }
  validates :related_publications, url: true, if: -> { related_publications.present? }
  validates :related_datasets, url: true, if: -> { related_datasets.present? }
  validates :rights_documentation, url: true, if: -> { rights_documentation.present? }
  before_save :index_preservation_workflow_terms

  property :abstract, predicate: "http://purl.org/dc/elements/1.1/description", multiple: false do |index|
    index.as :stored_searchable
  end

  property :access_restriction_notes, predicate: "http://purl.org/dc/terms/accessRights" do |index|
    index.as :stored_searchable
  end

  property :administrative_unit, predicate: "http://id.loc.gov/vocabulary/relators/cur", multiple: false do |index|
    index.as :stored_searchable
  end

  property :author_notes, predicate: "http://metadata.emory.edu/vocab/cor-terms#authorNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :conference_dates, predicate: "http://rdaregistry.info/Elements/u/P60526", multiple: false do |index|
    index.as :stored_searchable, :dateable, :facetable
  end

  property :conference_name, predicate: "http://purl.org/dc/terms/relation#conferenceOrMeeting", multiple: false do |index|
    index.as :stored_searchable
  end

  property :contact_information, predicate: "http://www.rdaregistry.info/Elements/u/#P60490", multiple: false do |index|
    index.as :stored_searchable
  end

  property :content_genres, predicate: "http://www.europeana.edu/schemas/edm/hasType" do |index|
    index.as :stored_searchable, :facetable
  end

  property :content_type, predicate: "http://purl.org/dc/terms/type", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :contributors, predicate: "http://purl.org/dc/elements/1.1/contributor" do |index|
    index.as :stored_searchable
  end

  property :copyright_date, predicate: "http://purl.org/dc/terms/dateCopyrighted", multiple: false do |index|
    index.as :stored_searchable, :dateable, :facetable
  end

  property :creator, predicate: "http://purl.org/dc/elements/1.1/creator" do |index|
    index.as :stored_searchable, :facetable, :sortable
  end

  property :data_classifications, predicate: "http://metadata.emory.edu/vocab/cor-terms#dataClassification" do |index|
    index.as :stored_searchable
  end

  property :data_collection_dates, predicate: "http://metadata.emory.edu/vocab/cor-terms#dataCollectionDates" do |index|
    index.as :stored_searchable, :dateable, :facetable
  end

  property :data_producers, predicate: "http://id.loc.gov/vocabulary/relators/prv" do |index|
    index.as :stored_searchable
  end

  property :data_source_notes, predicate: "http://metadata.emory.edu/vocab/cor-terms#dataSourcesNote" do |index|
    index.as :stored_searchable
  end

  property :date_created, predicate: "http://purl.org/dc/terms/created", multiple: false do |index|
    index.as :stored_searchable, :facetable, :dateable, :sortable
  end

  property :date_digitized, predicate: "http://metadata.emory.edu/vocab/cor-terms#dateDigitized", multiple: false do |index|
    index.as :stored_searchable, :dateable, :facetable
  end

  property :date_issued, predicate: "http://purl.org/dc/terms/issued", multiple: false do |index|
    index.as :stored_searchable, :dateable, :facetable, :sortable
  end

  property :edition, predicate: "http://id.loc.gov/ontologies/bibframe/editionStatement", multiple: false do |index|
    index.as :stored_searchable
  end

  property :emory_ark, predicate: "http://id.loc.gov/vocabulary/identifiers/local#ark" do |index|
    index.as :stored_searchable
  end

  property :emory_rights_statements, predicate: "http://purl.org/dc/elements/1.1/rights" do |index|
    index.as :stored_searchable
  end

  property :extent, predicate: "http://www.rdaregistry.info/Elements/u/#P60550", multiple: false do |index|
    index.as :stored_searchable
  end

  property :final_published_versions, predicate: "http://purl.org/dc/terms/hasVersion" do |index|
    index.as :stored_searchable
  end

  property :geographic_unit, predicate: "http://metadata.emory.edu/vocab/cor-terms#geographicUnit", multiple: false do |index|
    index.as :stored_searchable
  end

  property :grant_agencies, predicate: "http://id.loc.gov/vocabulary/relators/fnd" do |index|
    index.as :stored_searchable
  end

  property :grant_information, predicate: "http://metadata.emory.edu/vocab/cor-terms#grantOrFundingNote" do |index|
    index.as :stored_searchable
  end

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

  property :issue, predicate: "http://purl.org/ontology/bibo/issue", multiple: false do |index|
    index.as :stored_searchable
  end

  property :keywords, predicate: "http://schema.org/keywords" do |index|
    index.as :stored_searchable
  end

  property :legacy_rights, predicate: "http://metadata.emory.edu/vocab/cor-terms#legacyRights", multiple: false do |index|
    index.as :stored_searchable
  end

  property :local_call_number, predicate: "http://metadata.emory.edu/vocab/cor-terms#localCallNumber", multiple: false do |index|
    index.as :stored_searchable
  end

  property :notes, predicate: "http://www.w3.org/2004/02/skos/core#note" do |index|
    index.as :stored_searchable
  end

  property :other_identifiers, predicate: "http://id.loc.gov/vocabulary/identifiers/local#legacy" do |index|
    index.as :stored_searchable
  end

  property :page_range_end, predicate: "http://purl.org/ontology/bibo/pageEnd", multiple: false do |index|
    index.as :stored_searchable
  end

  property :page_range_start, predicate: "http://purl.org/ontology/bibo/pageStart", multiple: false do |index|
    index.as :stored_searchable
  end

  property :parent_title, predicate: "http://rdaregistry.info/Elements/u/P60101", multiple: false do |index|
    index.as :stored_searchable
  end

  property :place_of_production, predicate: "http://id.loc.gov/vocabulary/relators/pup", multiple: false do |index|
    index.as :stored_searchable
  end

  property :preservation_event, predicate: "http://metadata.emory.edu/vocab/cor-terms#preservation_event", class_name: "PreservationEvent"

  property :preservation_workflow, predicate: "http://metadata.emory.edu/vocab/cor-terms#preservation_workflow", class_name: "PreservationWorkflow"

  property :preservation_workflow_terms, predicate: "http://metadata.emory.edu/vocab/cor-terms#preservation_workflow_attributes" do |index|
    index.as :stored_searchable, :facetable
  end

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

  property :re_use_license, predicate: "http://schema.org/license", multiple: false do |index|
    index.as :stored_searchable
  end

  property :related_datasets, predicate: "http://purl.org/dc/terms/relation#dataset" do |index|
    index.as :stored_searchable
  end

  property :related_material_notes, predicate: "http://purl.org/dc/elements/1.1/relation" do |index|
    index.as :stored_searchable
  end

  property :related_publications, predicate: "http://purl.org/dc/terms/relation#publication" do |index|
    index.as :stored_searchable
  end

  property :rights_documentation, predicate: "http://metadata.emory.edu/vocab/cor-terms#rightsDocumentationURI", multiple: false do |index|
    index.as :stored_searchable
  end

  property :rights_holders, predicate: "http://purl.org/dc/terms/rightsHolder" do |index|
    index.as :stored_searchable
  end

  property :rights_statement, predicate: "http://www.europeana.eu/schemas/edm/rights" do |index|
    index.as :stored_searchable, :facetable
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

  property :sponsor, predicate: "http://id.loc.gov/vocabulary/relators/spn", multiple: false do |index|
    index.as :stored_searchable
  end

  property :staff_notes, predicate: "http://metadata.emory.edu/vocab/cor-terms#staffNote" do |index|
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

  property :volume, predicate: "http://purl.org/ontology/bibo/volume", multiple: false do |index|
    index.as :stored_searchable
  end

  property :deduplication_key, predicate: "http://metadata.emory.edu/vocab/predicates#deduplicationKey", multiple: false do |index|
    index.as :stored_searchable
  end

  def index_preservation_workflow_terms
    self.preservation_workflow_terms = preservation_workflow.map(&:preservation_terms)
  end

  # accepts_nested_attributes_for can not be called until all
  # the properties are declared because it calls resource_class,
  # which finalizes the propery declarations.
  # See https://github.com/projecthydra/active_fedora/issues/847

  # rubocop:disable Layout/AlignHash
  accepts_nested_attributes_for :preservation_workflow, allow_destroy: true,
    reject_if:  proc { |attrs|
                  ['workflow_type', 'workflow_notes', 'workflow_rights_basis',
                   'workflow_rights_basis_note', 'workflow_rights_basis_date',
                   'workflow_rights_basis_reviewer', 'workflow_rights_basis_uri'].all? do |key|
                     Array(attrs[key]).all?(&:blank?)
                   end
                }

  accepts_nested_attributes_for :preservation_event, allow_destroy: true,
    reject_if:  proc { |attrs|
                  ['event_id', 'event_type', 'work_id',
                   'initiating_user', 'event_start',
                   'event_end', 'outcome', 'fileset_id',
                   'software_version', 'workflow_id', 'event_details'].all? do |key|
                     Array(attrs[key]).all?(&:blank?)
                   end
                }
  # rubocop:enable Layout/AlignHash
end
