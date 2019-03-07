# Generated via
#  `rails generate hyrax:work CurateGenericWork`
class CurateGenericWork < ActiveFedora::Base
  include ::Hyrax::WorkBehavior

  self.indexer = CurateGenericWorkIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

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

  property :content_genre, predicate: "http://www.europeana.eu/schemas/edm/" do |index|
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

  property :parent_title, predicate: "http://id.loc.gov/ontologies/bibframe/seriesStatement", multiple: false do |index|
    index.as :stored_searchable
  end

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata
end
