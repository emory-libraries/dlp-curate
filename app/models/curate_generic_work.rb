# Generated via
#  `rails generate hyrax:work CurateGenericWork`
class CurateGenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  self.indexer = CurateGenericWorkIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }
  validates :date_created_work, :date_issued, :conference_dates, :copyright_date, :scheduled_rights_review, type: Date

  property :institution, predicate: "http://rdaregistry.info/Elements/u/P60402", multiple: false do |index|
    index.as :stored_searchable
  end

  property :holding_repository, predicate: "http://id.loc.gov/vocabulary/relators/rps", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :administrative_unit, predicate: "http://id.loc.gov/vocabulary/relators/cur", multiple: false do |index|
    index.as :stored_searchable
  end

  property :sublocation, predicate: "http://metadata.emory.edu/vocab/cor-terms#physicalSublocation", multiple: false do |index|
    index.as :stored_searchable
  end

  property :content_type, predicate: "http://purl.org/dc/terms/type", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :content_genre, predicate: "http://www.europeana.edu/schemas/edm/hasType" do |index|
    index.as :stored_searchable, :facetable
  end

  property :abstract, predicate: "http://purl.org/dc/elements/1.1/description", multiple: false do |index|
    index.as :stored_searchable
  end

  property :table_of_contents, predicate: "http://purl.org/dc/terms/tableOfContents", multiple: false do |index|
    index.as :stored_searchable
  end

  property :edition, predicate: "http://id.loc.gov/ontologies/bibframe/editionStatement", multiple: false

  property :primary_language, predicate: "http://purl.org/dc/elements/1.1/language", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_topics, predicate: "http://purl.org/dc/elements/1.1/subject" do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_names, predicate: "http://purl.org/dc/elements/1.1/subject#names" do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_geo, predicate: "http://purl.org/dc/elements/1.1/coverage" do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_time_periods, predicate: "http://schema.org/temporalCoverage" do |index|
    index.as :stored_searchable
  end

  property :conference_name, predicate: "http://purl.org/dc/terms/relation#conferenceOrMeeting", multiple: false do |index|
    index.as :stored_searchable
  end

  property :uniform_title, predicate: "http://purl.org/dc/elements/1.1/title", multiple: false do |index|
    index.as :stored_searchable
  end

  property :series_title, predicate: "http://id.loc.gov/ontologies/bibframe/seriesStatement", multiple: false do |index|
    index.as :stored_searchable
  end

  property :parent_title, predicate: "http://rdaregistry.info/Elements/u/P60101", multiple: false do |index|
    index.as :stored_searchable
  end

  property :contact_information, predicate: "http://www.rdaregistry.info/Elements/u/#P60490", multiple: false do |index|
    index.as :stored_searchable
  end

  property :publisher_version, predicate: "http://metadata.emory.edu/vocab/cor-terms#publicationStage", multiple: false do |index|
    index.as :stored_searchable
  end

  property :creator, predicate: "http://purl.org/dc/elements/1.1/creator" do |index|
    index.as :stored_searchable, :facetable
  end

  property :contributor, predicate: "http://purl.org/dc/elements/1.1/contributor" do |index|
    index.as :stored_searchable
  end

  property :sponsor, predicate: "http://id.loc.gov/vocabulary/relators/spn", multiple: false

  property :data_producer, predicate: "http://id.loc.gov/vocabulary/relators/prv" do |index|
    index.as :stored_searchable
  end

  property :grant, predicate: "http://id.loc.gov/vocabulary/relators/fnd" do |index|
    index.as :stored_searchable
  end

  property :grant_information, predicate: "http://metadata.emory.edu/vocab/cor-terms#grantOrFundingNote"

  property :author_notes, predicate: "http://metadata.emory.edu/vocab/cor-terms#authorNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :note, predicate: "http://www.w3.org/2004/02/skos/core#note" do |index|
    index.as :stored_searchable
  end

  property :data_source_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#dataSourcesNote" do |index|
    index.as :stored_searchable
  end

  property :geographic_unit, predicate: "http://metadata.emory.edu/vocab/cor-terms#geographicUnit", multiple: false do |index|
    index.as :stored_searchable
  end

  property :technical_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#technicalNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :issn, predicate: "http://id.loc.gov/vocabulary/identifiers/issn", multiple: false do |index|
    index.as :stored_searchable
  end

  property :isbn, predicate: "http://id.loc.gov/vocabulary/identifiers/isbn", multiple: false do |index|
    index.as :stored_searchable
  end

  property :related_publications, predicate: "http://purl.org/dc/terms/relation#publication"
  property :related_datasets, predicate: "http://purl.org/dc/terms/relation#dataset"
  property :extent, predicate: "http://www.rdaregistry.info/Elements/u/#P60550", multiple: false

  property :date_issued, predicate: "http://purl.org/dc/terms/issued", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :conference_dates, predicate: "http://rdaregistry.info/Elements/u/P60526", multiple: false

  property :data_collection_dates, predicate: "http://schema.org/temporalCoverage" do |index|
    index.as :stored_searchable
  end

  property :local_call_number, predicate: "http://metadata.emory.edu/vocab/cor-terms#localCallNumber", multiple: false do |index|
    index.as :stored_searchable
  end

  property :related_material, predicate: "http://purl.org/dc/elements/1.1/relation" do |index|
    index.as :stored_searchable
  end

  property :final_published_version, predicate: "http://purl.org/dc/terms/hasVersion"

  property :issue, predicate: "http://purl.org/ontology/bibo/issue", multiple: false

  property :page_range_start, predicate: "http://purl.org/ontology/bibo/pageStart", multiple: false

  property :page_range_end, predicate: "http://purl.org/ontology/bibo/pageEnd", multiple: false

  property :volume, predicate: "http://purl.org/ontology/bibo/volume", multiple: false

  property :place_of_production, predicate: "http://id.loc.gov/vocabulary/relators/pup", multiple: false

  property :keywords, predicate: "http://schema.org/keywords" do |index|
    index.as :stored_searchable
  end

  property :rights_statement, predicate: "http://purl.org/dc/elements/1.1/rights"

  property :rights_statement_controlled, predicate: "http://www.europeana.eu/schemas/edm/rights", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :rights_holder, predicate: "http://purl.org/dc/terms/rightsHolder"

  property :copyright_date, predicate: "http://purl.org/dc/terms/dateCopyrighted", multiple: false do |index|
    index.as :stored_searchable
  end

  property :access_right, predicate: "http://purl.org/dc/terms/accessRights" do |index|
    index.as :stored_searchable
  end

  property :rights_documentation, predicate: "http://metadata.emory.edu/vocab/cor-terms#rightsDocumentationURI", multiple: false

  property :scheduled_rights_review, predicate: "http://metadata.emory.edu/vocab/cor-terms#scheduledRightsReview", multiple: false do |index|
    index.as :stored_searchable
  end

  property :scheduled_rights_review_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#scheduledRightsReviewNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :internal_rights_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#internalRightsNote", multiple: false do |index|
    index.as :stored_searchable
  end

  property :legacy_rights, predicate: "http://metadata.emory.edu/vocab/cor-terms#legacyRights", multiple: false do |index|
    index.as :stored_searchable
  end

  property :data_classification, predicate: "http://metadata.emory.edu/vocab/cor-terms#dataClassification" do |index|
    index.as :stored_searchable
  end

  property :sensitive_material, predicate: "http://metadata.emory.edu/vocab/cor-terms#sensitiveMaterial", multiple: false do |index|
    index.as :stored_searchable
  end

  property :sensitive_material_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#sensitiveMaterialNote", multiple: false do |index|
    index.as :stored_searchable
  end
  property :staff_note, predicate: "http://metadata.emory.edu/vocab/cor-terms#staffNote" do |index|
    index.as :stored_searchable
  end

  property :date_digitized, predicate: "http://metadata.emory.edu/vocab/cor-terms#dateDigitized", multiple: false do |index|
    index.as :stored_searchable
  end

  property :transfer_engineer, predicate: "http://metadata.emory.edu/vocab/cor-terms#fileTransferEngineer", multiple: false do |index|
    index.as :stored_searchable
  end

  property :legacy_identifier, predicate: "http://id.loc.gov/vocabulary/identifiers/local#legacy" do |index|
    index.as :stored_searchable
  end

  property :legacy_ark, predicate: "http://id.loc.gov/vocabulary/identifiers/local#ark" do |index|
    index.as :stored_searchable
  end

  property :system_of_record_ID, predicate: "http://metadata.emory.edu/vocab/cor-terms#descriptiveSystemID", multiple: false do |index|
    index.as :stored_searchable
  end

  property :primary_repository_ID, predicate: "http://purl.org/dc/terms/identifier", multiple: false do |index|
    index.as :stored_searchable
  end

  property :license, predicate: "http://schema.org/license", multiple: false

  property :publisher, predicate: "http://purl.org/dc/elements/1.1/publisher", multiple: false do |index|
    index.as :stored_searchable
  end

  property :date_created, predicate: "http://purl.org/dc/terms/created", multiple: false do |index|
    index.as :stored_searchable, :facetable
  end
end
