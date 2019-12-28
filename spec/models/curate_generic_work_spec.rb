# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work CurateGenericWork`
require 'rails_helper'

RSpec.describe CurateGenericWork do
  context "multi-part objects" do
    let(:work1)       { FactoryBot.build(:work, id: 'wk1', title: ['Work 1']) }
    let(:work2)       { FactoryBot.build(:work, id: 'wk2', title: ['Work 2']) }
    let(:work3)       { FactoryBot.build(:work, id: 'wk3', title: ['Work 3']) }
    let(:fileset1)    { FactoryBot.build(:file_set, id: 'fs1', title: ['Fileset 1']) }
    let(:fileset2)    { FactoryBot.build(:file_set, id: 'fs2', title: ['Fileset 2']) }

    before do
      work1.members = [work2, work3, fileset1, fileset2]
      pres_workflow = work1.preservation_workflow.build
      pres_workflow.workflow_type = 'default'
      pres_workflow.workflow_notes = 'note example'
      pres_workflow.persist!
      work1.save!
      work1.reload
    end

    it 'access multi-part objects' do
      w_members = work1.members
      expect(w_members.map(&:id)).to match_array [work2.id, work3.id, fileset1.id, fileset2.id]
    end

    it "has a preservation workflow which is a PreservationWorkflow object" do
      expect(work2.preservation_workflow.build).to be_instance_of PreservationWorkflow
    end

    it "has a preservation event which is a PreservationEvent object" do
      expect(work2.preservation_event.build).to be_instance_of PreservationEvent
    end

    it "access preservation workflow properties after saving" do
      expect(work1.preservation_workflow.map(&:workflow_type).flatten).to include(['default'])
    end

    it "checks assign id" do
      expect(work1.assign_id).to match(/\d{3}[A-z0-9]{7}-cor/)
    end
  end

  describe "#institution" do
    subject { described_class.new }
    let(:institution) { 'Emory University' }

    context "with new CurateGenericWork work" do
      its(:institution) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has an institution" do
      subject do
        described_class.create.tap do |cgw|
          cgw.institution = institution
        end
      end
      its(:institution) { is_expected.to eq 'Emory University' }
    end
  end

  describe "#holding_repository" do
    subject { described_class.new }
    let(:holding_repository) { 'Woodruff' }

    context "with new CurateGenericWork work" do
      its(:holding_repository) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a holding_repository" do
      subject do
        described_class.create.tap do |cgw|
          cgw.holding_repository = holding_repository
        end
      end
      its(:holding_repository) { is_expected.to eq 'Woodruff' }
    end
  end

  describe "#administrative_unit" do
    subject { described_class.new }
    let(:administrative_unit) { 'LTDS' }

    context "with new CurateGenericWork work" do
      its(:administrative_unit) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has an administrative_unit" do
      subject do
        described_class.create.tap do |cgw|
          cgw.administrative_unit = administrative_unit
        end
      end
      its(:administrative_unit) { is_expected.to eq 'LTDS' }
    end
  end

  describe "#sublocation" do
    subject { described_class.new }
    let(:sublocation) { 'Box Folder' }

    context "with new CurateGenericWork work" do
      its(:sublocation) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a sublocation" do
      subject do
        described_class.create.tap do |cgw|
          cgw.sublocation = sublocation
        end
      end
      its(:sublocation) { is_expected.to eq 'Box Folder' }
    end
  end

  describe "#content_type" do
    subject { described_class.new }
    let(:content_type) { 'Book' }

    context "with new CurateGenericWork work" do
      its(:content_type) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a content_type" do
      subject do
        described_class.create.tap do |cgw|
          cgw.content_type = content_type
        end
      end
      its(:content_type) { is_expected.to eq 'Book' }
    end
  end

  describe "#content_genres" do
    subject { described_class.new }
    let(:content_genres) { ['Fictional book', 'Another Book'] }

    context "with new CurateGenericWork work" do
      its(:content_genres) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has content_genres" do
      subject do
        described_class.create.tap do |cgw|
          cgw.content_genres = content_genres
        end
      end
      its(:content_genres) { is_expected.to eq ['Fictional book', 'Another Book'] }
    end
  end

  describe "#abstract" do
    subject { described_class.new }
    let(:abstract) { 'This is an abstract of an ETD' }

    context "with new CurateGenericWork work" do
      its(:abstract) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has an abstract" do
      subject do
        described_class.create.tap do |cgw|
          cgw.abstract = abstract
        end
      end
      its(:abstract) { is_expected.to include 'abstract of an ETD' }
    end
  end

  describe "#table_of_contents" do
    subject { described_class.new }
    let(:table_of_contents) { 'This is an example table of contents' }

    context "with new CurateGenericWork work" do
      its(:table_of_contents) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a table_of_contents" do
      subject do
        described_class.create.tap do |cgw|
          cgw.table_of_contents = table_of_contents
        end
      end
      its(:table_of_contents) { is_expected.to include 'example' }
    end
  end

  describe "#edition" do
    subject { described_class.new }
    let(:edition) { 'Version 2.0' }

    context "with new CurateGenericWork work" do
      its(:edition) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has an edition" do
      subject do
        described_class.create.tap do |cgw|
          cgw.edition = edition
        end
      end
      its(:edition) { is_expected.to include '2.0' }
    end
  end

  describe "#primary_language" do
    subject { described_class.new }
    let(:primary_language) { 'English' }

    context "with new CurateGenericWork work" do
      its(:primary_language) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a primary_language" do
      subject do
        described_class.create.tap do |cgw|
          cgw.primary_language = primary_language
        end
      end
      its(:primary_language) { is_expected.to eq 'English' }
    end
  end

  describe "#subject_topics" do
    subject { described_class.new }
    let(:subject_topics) { ['Religion'] }

    context "with new CurateGenericWork work" do
      its(:subject_topics) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a subject_topics" do
      subject do
        described_class.create.tap do |cgw|
          cgw.subject_topics = subject_topics
        end
      end
      its(:subject_topics) { is_expected.to eq(['Religion']) }
    end
  end

  describe "#subject_names" do
    subject { described_class.new }
    let(:subject_names) { ['Example Name'] }

    context "with new CurateGenericWork work" do
      its(:subject_names) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a subject_names" do
      subject do
        described_class.create.tap do |cgw|
          cgw.subject_names = subject_names
        end
      end
      its(:subject_names) { is_expected.to eq(['Example Name']) }
    end
  end

  describe "#subject_geo" do
    subject { described_class.new }
    let(:subject_geo) { ['United States'] }

    context "with new CurateGenericWork work" do
      its(:subject_geo) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a subject_geo" do
      subject do
        described_class.create.tap do |cgw|
          cgw.subject_geo = subject_geo
        end
      end
      its(:subject_geo) { is_expected.to eq(['United States']) }
    end
  end

  describe "#subject_time_periods" do
    subject { described_class.new }
    let(:subject_time_periods) { ['Byzantine era (330–1453)'] }

    context "with new CurateGenericWork work" do
      its(:subject_time_periods) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a subject_time_periods" do
      subject do
        described_class.create.tap do |cgw|
          cgw.subject_time_periods = subject_time_periods
        end
      end
      its(:subject_time_periods) { is_expected.to eq(['Byzantine era (330–1453)']) }
    end
  end

  describe "#conference_name" do
    subject { described_class.new }
    let(:conference_name) { 'Samvera Connect' }

    context "with new CurateGenericWork work" do
      its(:conference_name) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a conference_name" do
      subject do
        described_class.create.tap do |cgw|
          cgw.conference_name = conference_name
        end
      end
      its(:conference_name) { is_expected.to include 'Samvera' }
    end
  end

  describe "#uniform_title" do
    subject { described_class.new }
    let(:uniform_title) { 'Shakespeare, William ... Othello' }

    context "with new CurateGenericWork work" do
      its(:uniform_title) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a uniform_title" do
      subject do
        described_class.create.tap do |cgw|
          cgw.uniform_title = uniform_title
        end
      end
      its(:uniform_title) { is_expected.to include 'Shakespeare' }
    end
  end

  describe "#series_title" do
    subject { described_class.new }
    let(:series_title) { 'Star Wars' }

    context "with new CurateGenericWork work" do
      its(:series_title) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a series_title" do
      subject do
        described_class.create.tap do |cgw|
          cgw.series_title = series_title
        end
      end
      its(:series_title) { is_expected.to eq 'Star Wars' }
    end
  end

  describe "#parent_title" do
    subject { described_class.new }
    let(:parent_title) { 'Nature' }

    context "with new CurateGenericWork work" do
      its(:parent_title) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a parent_title" do
      subject do
        described_class.create.tap do |cgw|
          cgw.parent_title = parent_title
        end
      end
      its(:parent_title) { is_expected.to eq 'Nature' }
    end
  end

  describe "#contact_information" do
    subject { described_class.new }
    let(:contact_information) { 'Contact me at this email: example@example.com' }

    context "with new CurateGenericWork work" do
      its(:contact_information) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a contact_information" do
      subject do
        described_class.create.tap do |cgw|
          cgw.contact_information = contact_information
        end
      end
      its(:contact_information) { is_expected.to include 'Contact' }
    end
  end

  describe "#publisher_version" do
    subject { described_class.new }
    let(:publisher_version) { 'Final Version' }

    context "with new CurateGenericWork work" do
      its(:publisher_version) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a publisher_version" do
      subject do
        described_class.create.tap do |cgw|
          cgw.publisher_version = publisher_version
        end
      end
      its(:publisher_version) { is_expected.to include 'Version' }
    end
  end

  describe "#creator" do
    subject { described_class.new }
    let(:creator) { ['William Shakespeare'] }

    context "with new CurateGenericWork work" do
      its(:creator) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a creator" do
      subject do
        described_class.create.tap do |cgw|
          cgw.creator = creator
        end
      end
      its(:creator) { is_expected.to eq(['William Shakespeare']) }
    end
  end

  describe "#contributors" do
    subject { described_class.new }
    let(:contributors) { ['Leo Tolstoy'] }

    context "with new CurateGenericWork work" do
      its(:contributors) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has contributors" do
      subject do
        described_class.create.tap do |cgw|
          cgw.contributors = contributors
        end
      end
      its(:contributors) { is_expected.to eq(['Leo Tolstoy']) }
    end
  end

  describe "#sponsor" do
    subject { described_class.new }
    let(:sponsor) { 'Coca-Cola' }

    context "with new CurateGenericWork work" do
      its(:sponsor) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a sponsor" do
      subject do
        described_class.create.tap do |cgw|
          cgw.sponsor = sponsor
        end
      end
      its(:sponsor) { is_expected.to include 'Coca-Cola' }
    end
  end

  describe "#data_producers" do
    subject { described_class.new }
    let(:data_producers) { ['Emory University'] }

    context "with new CurateGenericWork work" do
      its(:data_producers) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has data_producers" do
      subject do
        described_class.create.tap do |cgw|
          cgw.data_producers = data_producers
        end
      end
      its(:data_producers) { is_expected.to eq(['Emory University']) }
    end
  end

  describe "#grant_agencies" do
    subject { described_class.new }
    let(:grant_agencies) { ['NIH'] }

    context "with new CurateGenericWork work" do
      its(:grant_agencies) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has grant_agencies" do
      subject do
        described_class.create.tap do |cgw|
          cgw.grant_agencies = grant_agencies
        end
      end
      its(:grant_agencies) { is_expected.to eq(['NIH']) }
    end
  end

  describe "#grant_information" do
    subject { described_class.new }
    let(:grant_information) { ['This grant was provided in 2011'] }

    context "with new CurateGenericWork work" do
      its(:grant_information) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a grant_information" do
      subject do
        described_class.create.tap do |cgw|
          cgw.grant_information = grant_information
        end
      end
      its(:grant_information) { is_expected.to eq(['This grant was provided in 2011']) }
    end
  end

  describe "#author_notes" do
    subject { described_class.new }
    let(:author_notes) { 'She was born in 1923' }

    context "with new CurateGenericWork work" do
      its(:author_notes) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a author_notes" do
      subject do
        described_class.create.tap do |cgw|
          cgw.author_notes = author_notes
        end
      end
      its(:author_notes) { is_expected.to include '1923' }
    end
  end

  describe "#notes" do
    subject { described_class.new }
    let(:notes) { ['general note'] }

    context "with new CurateGenericWork work" do
      its(:notes) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has notes" do
      subject do
        described_class.create.tap do |cgw|
          cgw.notes = notes
        end
      end
      its(:notes) { is_expected.to eq(['general note']) }
    end
  end

  describe "#data_source_notes" do
    subject { described_class.new }
    let(:data_source_notes) { ['general data source note'] }

    context "with new CurateGenericWork work" do
      its(:data_source_notes) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has data_source_notes" do
      subject do
        described_class.create.tap do |cgw|
          cgw.data_source_notes = data_source_notes
        end
      end
      its(:data_source_notes) { is_expected.to eq(['general data source note']) }
    end
  end

  describe "#geographic_unit" do
    subject { described_class.new }
    let(:geographic_unit) { 'Vayaha Village' }

    context "with new CurateGenericWork work" do
      its(:geographic_unit) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a geographic_unit" do
      subject do
        described_class.create.tap do |cgw|
          cgw.geographic_unit = geographic_unit
        end
      end
      its(:geographic_unit) { is_expected.to include 'Vayaha' }
    end
  end

  describe "#technical_note" do
    subject { described_class.new }
    let(:technical_note) { 'open source repository software' }

    context "with new CurateGenericWork work" do
      its(:technical_note) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a technical_note" do
      subject do
        described_class.create.tap do |cgw|
          cgw.technical_note = technical_note
        end
      end
      its(:technical_note) { is_expected.to include 'software' }
    end
  end

  describe "#issn" do
    subject { described_class.new }
    let(:issn) { '2039-4032' }

    context "with new CurateGenericWork work" do
      its(:issn) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a issn" do
      subject do
        described_class.create.tap do |cgw|
          cgw.issn = issn
        end
      end
      its(:issn) { is_expected.to include '2039-4032' }
    end
  end

  describe "#isbn" do
    subject { described_class.new }
    let(:isbn) { '978-3-16-148410-0' }

    context "with new CurateGenericWork work" do
      its(:isbn) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a isbn" do
      subject do
        described_class.create.tap do |cgw|
          cgw.isbn = isbn
        end
      end
      its(:isbn) { is_expected.to include '978-3-16-148410-0' }
    end
  end

  describe "#related_publications" do
    subject { described_class.new }
    let(:related_publications) { ['beauty and the beast'] }

    context "with new CurateGenericWork work" do
      its(:related_publications) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a related_publications" do
      subject do
        described_class.create.tap do |cgw|
          cgw.related_publications = related_publications
        end
      end
      its(:related_publications) { is_expected.to eq(['beauty and the beast']) }
    end
  end

  describe "#related_datasets" do
    subject { described_class.new }
    let(:related_datasets) { ['Image Processing Dataset'] }

    context "with new CurateGenericWork work" do
      its(:related_datasets) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a related_datasets" do
      subject do
        described_class.create.tap do |cgw|
          cgw.related_datasets = related_datasets
        end
      end
      its(:related_datasets) { is_expected.to eq(['Image Processing Dataset']) }
    end
  end

  describe "#extent" do
    subject { described_class.new }
    let(:extent) { '1920 x 1080' }

    context "with new CurateGenericWork work" do
      its(:extent) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has an extent" do
      subject do
        described_class.create.tap do |cgw|
          cgw.extent = extent
        end
      end
      its(:extent) { is_expected.to eq '1920 x 1080' }
    end
  end

  describe "#publisher" do
    subject { described_class.new }
    let(:publisher) { 'New publisher' }

    context "with new CurateGenericWork work" do
      its(:publisher) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a publisher" do
      subject do
        described_class.create.tap do |cgw|
          cgw.publisher = publisher
        end
      end
      its(:publisher) { is_expected.to eq publisher }
    end
  end

  describe "#date_created" do
    subject { described_class.new }
    let(:date_created) { Date.new(2018, 1, 12) }

    context "with new CurateGenericWork work" do
      its(:date_created) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a date_created" do
      subject do
        described_class.create.tap do |cgw|
          cgw.date_created = date_created
        end
      end
      its(:date_created) { is_expected.to eq date_created }
    end
  end

  describe "#date_issued" do
    subject { described_class.new }
    let(:date_issued) { Date.new(2018, 1, 12) }

    context "with new CurateGenericWork work" do
      its(:date_issued) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a date_issued" do
      subject do
        described_class.create.tap do |cgw|
          cgw.date_issued = date_issued
        end
      end
      its(:date_issued) { is_expected.to eq date_issued }
    end
  end

  describe "#conference_dates" do
    subject { described_class.new }
    let(:conference_dates) { Date.new(2018, 2, 24) }

    context "with new CurateGenericWork work" do
      its(:conference_dates) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has conference_dates" do
      subject do
        described_class.create.tap do |cgw|
          cgw.conference_dates = conference_dates
        end
      end
      its(:conference_dates) { is_expected.to eq conference_dates }
    end
  end

  describe "#data_collection_dates" do
    subject { described_class.new }
    let(:data_collection_dates) { [Date.new(2018, 3, 30)] }

    context "with new CurateGenericWork work" do
      its(:data_collection_dates) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has data_collection_dates" do
      subject do
        described_class.create.tap do |cgw|
          cgw.data_collection_dates = data_collection_dates
        end
      end
      its(:data_collection_dates) { is_expected.to eq data_collection_dates }
    end
  end

  describe "#local_call_number" do
    subject { described_class.new }
    let(:local_call_number) { '123' }

    context "with new CurateGenericWork work" do
      its(:local_call_number) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a local_call_number" do
      subject do
        described_class.create.tap do |cgw|
          cgw.local_call_number = local_call_number
        end
      end
      its(:local_call_number) { is_expected.to eq '123' }
    end
  end

  describe "#related_material_notes" do
    subject { described_class.new }
    let(:related_material_notes) { ['Free-text notes'] }

    context "with new CurateGenericWork work" do
      its(:related_material_notes) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has related_material_notes" do
      subject do
        described_class.create.tap do |cgw|
          cgw.related_material_notes = related_material_notes
        end
      end
      its(:related_material_notes) { is_expected.to eq ['Free-text notes'] }
    end
  end

  describe "#final_published_versions" do
    subject { described_class.new }
    let(:final_published_versions) { ['http://www.example.com'] }

    context "with new CurateGenericWork work" do
      its(:final_published_versions) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has final_published_versions" do
      subject do
        described_class.create.tap do |cgw|
          cgw.final_published_versions = final_published_versions
        end
      end
      its(:final_published_versions) { is_expected.to eq final_published_versions }
    end
  end

  describe "#issue" do
    subject { described_class.new }
    let(:issue) { '119(1-2):18-21' }

    context "with new CurateGenericWork work" do
      its(:issue) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has an issue" do
      subject do
        described_class.create.tap do |cgw|
          cgw.issue = issue
        end
      end
      its(:issue) { is_expected.to eq issue }
    end
  end

  describe "#page_range_start" do
    subject { described_class.new }
    let(:page_range_start) { '1-5' }

    context "with new CurateGenericWork work" do
      its(:page_range_start) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a page_range_start" do
      subject do
        described_class.create.tap do |cgw|
          cgw.page_range_start = page_range_start
        end
      end
      its(:page_range_start) { is_expected.to eq '1-5' }
    end
  end

  describe "#page_range_end" do
    subject { described_class.new }
    let(:page_range_end) { '15-20' }

    context "with new CurateGenericWork work" do
      its(:page_range_end) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a page_range_end" do
      subject do
        described_class.create.tap do |cgw|
          cgw.page_range_end = page_range_end
        end
      end
      its(:page_range_end) { is_expected.to eq '15-20' }
    end
  end

  describe "#volume" do
    subject { described_class.new }
    let(:volume) { 'Volume 2' }

    context "with new CurateGenericWork work" do
      its(:volume) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a volume" do
      subject do
        described_class.create.tap do |cgw|
          cgw.volume = volume
        end
      end
      its(:volume) { is_expected.to eq volume }
    end
  end

  describe "#place_of_production" do
    subject { described_class.new }
    let(:place_of_production) { 'Atlanta' }

    context "with new CurateGenericWork work" do
      its(:place_of_production) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a place_of_production" do
      subject do
        described_class.create.tap do |cgw|
          cgw.place_of_production = place_of_production
        end
      end
      its(:place_of_production) { is_expected.to eq 'Atlanta' }
    end
  end

  describe "#keywords" do
    subject { described_class.new }
    let(:keywords) { ['Biology', 'Physics'] }

    context "with new CurateGenericWork work" do
      its(:keywords) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has keywords" do
      subject do
        described_class.create.tap do |cgw|
          cgw.keywords = keywords
        end
      end
      its(:keywords) { is_expected.to eq keywords }
    end
  end

  describe "#rights_holders" do
    subject { described_class.new }
    let(:rights_holders) { ['Emory University'] }

    context "with new CurateGenericWork work" do
      its(:rights_holders) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has rights_holders" do
      subject do
        described_class.create.tap do |cgw|
          cgw.rights_holders = rights_holders
        end
      end
      its(:rights_holders) { is_expected.to eq rights_holders }
    end
  end

  describe "#rights_statement" do
    subject { described_class.new }
    let(:rights_statement) { 'Controlled Rights Statement' }

    context "with new CurateGenericWork work" do
      its(:rights_statement) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a rights_statement" do
      subject do
        described_class.create.tap do |cgw|
          cgw.rights_statement = [rights_statement]
        end
      end
      its(:rights_statement) { is_expected.to eq ['Controlled Rights Statement'] }
    end
  end

  describe "#emory_rights_statements" do
    subject { described_class.new }
    let(:emory_rights_statements) { ['Sample Rights Statement'] }

    context "with new CurateGenericWork work" do
      its(:emory_rights_statements) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has emory_rights_statements" do
      subject do
        described_class.create.tap do |cgw|
          cgw.emory_rights_statements = emory_rights_statements
        end
      end
      its(:emory_rights_statements) { is_expected.to eq emory_rights_statements }
    end
  end

  describe "#copyright_date" do
    subject { described_class.new }
    let(:copyright_date) { Date.new(2017, 3, 30) }

    context "with new CurateGenericWork work" do
      its(:copyright_date) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has copyright_date" do
      subject do
        described_class.create.tap do |cgw|
          cgw.copyright_date = copyright_date
        end
      end
      its(:copyright_date) { is_expected.to eq copyright_date }
    end
  end

  describe "#re_use_license" do
    subject { described_class.new }
    let(:re_use_license) { 'MIT Licence' }

    context "with new CurateGenericWork work" do
      its(:re_use_license) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has re_use_license" do
      subject do
        described_class.create.tap do |cgw|
          cgw.re_use_license = re_use_license
        end
      end
      its(:re_use_license) { is_expected.to eq re_use_license }
    end
  end

  describe "#access_restriction_notes" do
    subject { described_class.new }
    let(:access_restriction_notes) { ['Public Access'] }

    context "with new CurateGenericWork work" do
      its(:access_restriction_notes) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has access_restriction_notes" do
      subject do
        described_class.create.tap do |cgw|
          cgw.access_restriction_notes = access_restriction_notes
        end
      end
      its(:access_restriction_notes) { is_expected.to eq access_restriction_notes }
    end
  end

  describe "#rights_documentation" do
    subject { described_class.new }
    let(:rights_documentation) { 'Rights documentation uri' }

    context "with new CurateGenericWork work" do
      its(:rights_documentation) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has rights_documentation" do
      subject do
        described_class.create.tap do |cgw|
          cgw.rights_documentation = rights_documentation
        end
      end
      its(:rights_documentation) { is_expected.to eq rights_documentation }
    end
  end

  describe "#scheduled_rights_review" do
    subject { described_class.new }
    let(:scheduled_rights_review) { Date.new(2017, 3, 30) }

    context "with new CurateGenericWork work" do
      its(:scheduled_rights_review) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has scheduled_rights_review" do
      subject do
        described_class.create.tap do |cgw|
          cgw.scheduled_rights_review = scheduled_rights_review
        end
      end
      its(:scheduled_rights_review) { is_expected.to eq scheduled_rights_review }
    end
  end

  describe "#scheduled_rights_review_note" do
    subject { described_class.new }
    let(:scheduled_rights_review_note) { 'Review note' }

    context "with new CurateGenericWork work" do
      its(:scheduled_rights_review_note) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has scheduled_rights_review_note" do
      subject do
        described_class.create.tap do |cgw|
          cgw.scheduled_rights_review_note = scheduled_rights_review_note
        end
      end
      its(:scheduled_rights_review_note) { is_expected.to eq scheduled_rights_review_note }
    end
  end

  describe "#internal_rights_note" do
    subject { described_class.new }
    let(:internal_rights_note) { 'Internal review note' }

    context "with new CurateGenericWork work" do
      its(:internal_rights_note) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has internal_rights_note" do
      subject do
        described_class.create.tap do |cgw|
          cgw.internal_rights_note = internal_rights_note
        end
      end
      its(:internal_rights_note) { is_expected.to eq internal_rights_note }
    end
  end

  describe "#legacy_rights" do
    subject { described_class.new }
    let(:legacy_rights) { 'Legacy from prior institution' }

    context "with new CurateGenericWork work" do
      its(:legacy_rights) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has legacy_rights" do
      subject do
        described_class.create.tap do |cgw|
          cgw.legacy_rights = legacy_rights
        end
      end
      its(:legacy_rights) { is_expected.to eq legacy_rights }
    end
  end

  describe "#data_classifications" do
    subject { described_class.new }
    let(:data_classifications) { ['excel spreadsheet'] }

    context "with new CurateGenericWork work" do
      its(:data_classifications) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has data_classifications" do
      subject do
        described_class.create.tap do |cgw|
          cgw.data_classifications = data_classifications
        end
      end
      its(:data_classifications) { is_expected.to eq data_classifications }
    end
  end

  describe "#sensitive_material" do
    subject { described_class.new }
    let(:sensitive_material) { 'supplemental material' }

    context "with new CurateGenericWork work" do
      its(:sensitive_material) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has sensitive_material" do
      subject do
        described_class.create.tap do |cgw|
          cgw.sensitive_material = sensitive_material
        end
      end
      its(:sensitive_material) { is_expected.to eq sensitive_material }
    end
  end

  describe "#sensitive_material_note" do
    subject { described_class.new }
    let(:sensitive_material_note) { 'secret note' }

    context "with new CurateGenericWork work" do
      its(:sensitive_material_note) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has sensitive_material_note" do
      subject do
        described_class.create.tap do |cgw|
          cgw.sensitive_material_note = sensitive_material_note
        end
      end
      its(:sensitive_material_note) { is_expected.to eq sensitive_material_note }
    end
  end

  describe "#staff_notes" do
    subject { described_class.new }
    let(:staff_notes) { ['This is for internal staff use only'] }

    context "with new CurateGenericWork work" do
      its(:staff_notes) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has staff_notes" do
      subject do
        described_class.create.tap do |cgw|
          cgw.staff_notes = staff_notes
        end
      end
      its(:staff_notes) { is_expected.to eq staff_notes }
    end
  end

  describe "#date_digitized" do
    subject { described_class.new }
    let(:date_digitized) { Date.new(2018, 1, 12) }

    context "with new CurateGenericWork work" do
      its(:date_digitized) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a date_digitized" do
      subject do
        described_class.create.tap do |cgw|
          cgw.date_digitized = date_digitized
        end
      end
      its(:date_digitized) { is_expected.to eq date_digitized }
    end
  end

  describe "#transfer_engineer" do
    subject { described_class.new }
    let(:transfer_engineer) { 'John Doe' }

    context "with new CurateGenericWork work" do
      its(:transfer_engineer) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a transfer_engineer" do
      subject do
        described_class.create.tap do |cgw|
          cgw.transfer_engineer = transfer_engineer
        end
      end
      its(:transfer_engineer) { is_expected.to eq transfer_engineer }
    end
  end

  describe "#other_identifiers" do
    subject { described_class.new }
    let(:other_identifiers) { ['ETDs'] }

    context "with new CurateGenericWork work" do
      its(:other_identifiers) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has other_identifiers" do
      subject do
        described_class.create.tap do |cgw|
          cgw.other_identifiers = other_identifiers
        end
      end
      its(:other_identifiers) { is_expected.to eq other_identifiers }
    end
  end

  describe "#emory_ark" do
    subject { described_class.new }
    let(:emory_ark) { ['Emory Legacy Ark'] }

    context "with new CurateGenericWork work" do
      its(:emory_ark) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a emory_ark" do
      subject do
        described_class.create.tap do |cgw|
          cgw.emory_ark = emory_ark
        end
      end
      its(:emory_ark) { is_expected.to eq emory_ark }
    end
  end

  describe "#system_of_record_ID" do
    subject { described_class.new }
    let(:system_of_record_ID) { 'Alma:123' }

    context "with new CurateGenericWork work" do
      its(:system_of_record_ID) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a system_of_record_ID" do
      subject do
        described_class.create.tap do |cgw|
          cgw.system_of_record_ID = system_of_record_ID
        end
      end
      its(:system_of_record_ID) { is_expected.to eq system_of_record_ID }
    end
  end

  describe "#primary_repository_ID" do
    subject { described_class.new }
    let(:primary_repository_ID) { '123ABC' }

    context "with new CurateGenericWork work" do
      its(:primary_repository_ID) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a primary_repository_ID" do
      subject do
        described_class.create.tap do |cgw|
          cgw.primary_repository_ID = primary_repository_ID
        end
      end
      its(:primary_repository_ID) { is_expected.to eq primary_repository_ID }
    end
  end

  context "saves metadata in SolrDoc" do
    let(:params) do
      { title:                 ['Example Title'],
        primary_language:      'English',
        abstract:              'This is point number 1',
        content_type:          'http://id.loc.gov/vocabulary/resourceTypes/txt',
        rights_statement:      ['http://rightsstatements.org/vocab/InC/1.0/'],
        re_use_license:        'https://creativecommons.org/licenses/by/4.0/',
        date_created:          'XXXX-09-07',
        date_issued:           '193X',
        data_collection_dates: ['XXXX'],
        conference_dates:      '194X/195X',
        copyright_date:        '1942?/1944?' }
    end
    let(:curate_generic_work) { FactoryBot.build(:work, **params) }
    let(:solr_doc) { curate_generic_work.to_solr }

    it "returns the SolrDoc with metadata" do
      expect(solr_doc.keys).to include(
        'title_tesim', 'primary_language_tesim', 'abstract_tesim', 'content_type_tesim',
        'rights_statement_tesim', 're_use_license_tesim', 'date_created_tesim', 'date_issued_tesim',
        'data_collection_dates_tesim', 'conference_dates_tesim', 'copyright_date_tesim'
      )

      # Check title (multi-valued)
      expect(solr_doc['title_tesim']).to match_array params[:title]

      # Check primary_language (single-valued, stored-searchable, facetable)
      expect(solr_doc['primary_language_tesim']).to contain_exactly params[:primary_language]

      # Check abstract (single-valued, stored-searchable)
      expect(solr_doc['abstract_tesim']).to contain_exactly params[:abstract]

      # Check content_type_tesim also saved as url
      expect(solr_doc['content_type_tesim']).to contain_exactly params[:content_type]

      # Check content_type_tesim also saved as human_readable_content_type
      expect(solr_doc['human_readable_content_type_ssim']).to eq ['Text']

      # Check rights_statement_tesim also saved as url
      expect(solr_doc['rights_statement_tesim']).to contain_exactly params[:rights_statement].first

      # Check rights_statement_tesim also saved as human_readable_rights_statement
      expect(solr_doc['human_readable_rights_statement_ssim']).to eq ['In Copyright']

      # Check re_use_license_tesim also saved as url
      expect(solr_doc['re_use_license_tesim']).to contain_exactly params[:re_use_license]

      # Check re_use_license_tesim also saved as human_readable_re_use_license
      expect(solr_doc['human_readable_re_use_license_ssim']).to eq ['Creative Commons BY Attribution 4.0 International']

      # Check date_created_tesim also saved as date entered
      expect(solr_doc['date_created_tesim']).to contain_exactly params[:date_created]

      # Check date_created_tesim also saved as human_readable_date_created_tesim
      expect(solr_doc['human_readable_date_created_tesim']).to eq ['September 7, year unknown']

      # Check date_created_tesim also saved as year_created_isim
      expect(solr_doc['year_created_isim']).to be_nil

      # Check date_issued_tesim also saved as date entered
      expect(solr_doc['date_issued_tesim']).to contain_exactly params[:date_issued]

      # Check date_issued_tesim also saved as human_readable_date_issued_tesim
      expect(solr_doc['human_readable_date_issued_tesim']).to eq ['1930s']

      # Check date_issued_tesim also saved as year_issued_isim
      expect(solr_doc['year_issued_isim']).to eq [1930, 1931, 1932, 1933, 1934, 1935, 1936, 1937, 1938, 1939]

      # Check data_collection_dates_tesim also saved as date entered
      expect(solr_doc['data_collection_dates_tesim']).to contain_exactly params[:data_collection_dates].first

      # Check data_collection_dates_tesim also saved as human_readable_data_collection_dates_tesim
      expect(solr_doc['human_readable_data_collection_dates_tesim']).to eq ['unknown']

      # Check conference_dates_tesim also saved as date entered
      expect(solr_doc['conference_dates_tesim']).to contain_exactly params[:conference_dates]

      # Check conference_dates_tesim also saved as human_readable_conference_dates_tesim
      expect(solr_doc['human_readable_conference_dates_tesim']).to eq ['within the 1940s or 1950s']

      # Check copyright_date_tesim also saved as date entered
      expect(solr_doc['copyright_date_tesim']).to contain_exactly params[:copyright_date]

      # Check copyright_date_tesim also saved as human_readable_copyright_date_tesim
      expect(solr_doc['human_readable_copyright_date_tesim']).to eq ['between 1942 and 1944']
    end
  end

  context "saves custom terms for fields that use external vocabs" do
    let(:institution) { 'Test3' }

    let(:curate_generic_work) { FactoryBot.build(:work, institution: institution) }

    it "selects custom term and saves it" do
      curate_generic_work.save

      expect(curate_generic_work.institution).to eq institution
    end
  end

  context "validates url for work creation" do
    let(:bad_url) { 'teststring' }
    let(:curate_generic_work) { FactoryBot.build(:work, final_published_versions: [bad_url]) }

    it "does not save work with bad url" do
      curate_generic_work.save
      expect(curate_generic_work.errors.count).to eq 1
      expect(curate_generic_work.persisted?).to eq false
    end
  end
end
