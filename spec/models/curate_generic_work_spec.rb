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
      work1.save!
    end

    it 'access multi-part objects' do
      w_members = work1.members
      expect(w_members.map(&:id)).to match_array [work2.id, work3.id, fileset1.id, fileset2.id]
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

  describe "#content_genre" do
    subject { described_class.new }
    let(:content_genre) { ['Fictional book'] }

    context "with new CurateGenericWork work" do
      its(:content_genre) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a content_genre" do
      subject do
        described_class.create.tap do |cgw|
          cgw.content_genre = content_genre
        end
      end
      its(:content_genre) { is_expected.to eq ['Fictional book'] }
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

  describe "#contributor" do
    subject { described_class.new }
    let(:contributor) { ['Leo Tolstoy'] }

    context "with new CurateGenericWork work" do
      its(:contributor) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a contributor" do
      subject do
        described_class.create.tap do |cgw|
          cgw.contributor = contributor
        end
      end
      its(:contributor) { is_expected.to eq(['Leo Tolstoy']) }
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

  describe "#data_producer" do
    subject { described_class.new }
    let(:data_producer) { ['Emory University'] }

    context "with new CurateGenericWork work" do
      its(:data_producer) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a data_producer" do
      subject do
        described_class.create.tap do |cgw|
          cgw.data_producer = data_producer
        end
      end
      its(:data_producer) { is_expected.to eq(['Emory University']) }
    end
  end

  describe "#grant" do
    subject { described_class.new }
    let(:grant) { ['NIH'] }

    context "with new CurateGenericWork work" do
      its(:grant) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a grant" do
      subject do
        described_class.create.tap do |cgw|
          cgw.grant = grant
        end
      end
      its(:grant) { is_expected.to eq(['NIH']) }
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

  describe "#note" do
    subject { described_class.new }
    let(:note) { ['general note'] }

    context "with new CurateGenericWork work" do
      its(:note) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a note" do
      subject do
        described_class.create.tap do |cgw|
          cgw.note = note
        end
      end
      its(:note) { is_expected.to eq(['general note']) }
    end
  end

  describe "#data_source_note" do
    subject { described_class.new }
    let(:data_source_note) { ['general data source note'] }

    context "with new CurateGenericWork work" do
      its(:data_source_note) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a data_source_note" do
      subject do
        described_class.create.tap do |cgw|
          cgw.data_source_note = data_source_note
        end
      end
      its(:data_source_note) { is_expected.to eq(['general data source note']) }
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

  describe "#publisher_work" do
    subject { described_class.new }
    let(:publisher_work) { 'New publisher' }

    context "with new CurateGenericWork work" do
      its(:publisher_work) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a publisher" do
      subject do
        described_class.create.tap do |cgw|
          cgw.publisher_work = publisher_work
        end
      end
      its(:publisher_work) { is_expected.to eq publisher_work }
    end
  end

  describe "#date_created_work" do
    subject { described_class.new }
    let(:date_created_work) { Date.new(2018, 1, 12) }

    context "with new CurateGenericWork work" do
      its(:date_created_work) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a date_created" do
      subject do
        described_class.create.tap do |cgw|
          cgw.date_created_work = date_created_work
        end
      end
      its(:date_created_work) { is_expected.to eq date_created_work }
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

  describe "#related_material" do
    subject { described_class.new }
    let(:related_material) { ['Free-text notes'] }

    context "with new CurateGenericWork work" do
      its(:related_material) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a related_material" do
      subject do
        described_class.create.tap do |cgw|
          cgw.related_material = related_material
        end
      end
      its(:related_material) { is_expected.to eq ['Free-text notes'] }
    end
  end

  describe "#final_published_version" do
    subject { described_class.new }
    let(:final_published_version) { ['http://www.example.com'] }

    context "with new CurateGenericWork work" do
      its(:final_published_version) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a final_published_version" do
      subject do
        described_class.create.tap do |cgw|
          cgw.final_published_version = final_published_version
        end
      end
      its(:final_published_version) { is_expected.to eq final_published_version }
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

  describe "#rights_holder" do
    subject { described_class.new }
    let(:rights_holder) { ['Emory University'] }

    context "with new CurateGenericWork work" do
      its(:rights_holder) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has rights_holder" do
      subject do
        described_class.create.tap do |cgw|
          cgw.rights_holder = rights_holder
        end
      end
      its(:rights_holder) { is_expected.to eq rights_holder }
    end
  end

  describe "#rights_statement_controlled" do
    subject { described_class.new }
    let(:rights_statement_controlled) { 'Controlled Rights Statement' }

    context "with new CurateGenericWork work" do
      its(:rights_statement_controlled) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has a rights_statement_controlled" do
      subject do
        described_class.create.tap do |cgw|
          cgw.rights_statement_controlled = rights_statement_controlled
        end
      end
      its(:rights_statement_controlled) { is_expected.to eq 'Controlled Rights Statement' }
    end
  end

  describe "#rights_statement" do
    subject { described_class.new }
    let(:rights_statement) { ['Sample Rights Statement'] }

    context "with new CurateGenericWork work" do
      its(:rights_statement) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has rights_statement" do
      subject do
        described_class.create.tap do |cgw|
          cgw.rights_statement = rights_statement
        end
      end
      its(:rights_statement) { is_expected.to eq rights_statement }
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

  describe "#license_work" do
    subject { described_class.new }
    let(:license_work) { 'MIT Licence' }

    context "with new CurateGenericWork work" do
      its(:license_work) { is_expected.to be_falsey }
    end

    context "with a CurateGenericWork work that has license" do
      subject do
        described_class.create.tap do |cgw|
          cgw.license_work = license_work
        end
      end
      its(:license_work) { is_expected.to eq license_work }
    end
  end

  describe "#access_right" do
    subject { described_class.new }
    let(:access_right) { ['Public Access'] }

    context "with new CurateGenericWork work" do
      its(:access_right) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has access_right" do
      subject do
        described_class.create.tap do |cgw|
          cgw.access_right = access_right
        end
      end
      its(:access_right) { is_expected.to eq access_right }
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

  describe "#data_classification" do
    subject { described_class.new }
    let(:data_classification) { ['excel spreadsheet'] }

    context "with new CurateGenericWork work" do
      its(:data_classification) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has data_classification" do
      subject do
        described_class.create.tap do |cgw|
          cgw.data_classification = data_classification
        end
      end
      its(:data_classification) { is_expected.to eq data_classification }
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

  describe "#staff_note" do
    subject { described_class.new }
    let(:staff_note) { ['This is for internal staff use only'] }

    context "with new CurateGenericWork work" do
      its(:staff_note) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a staff_note" do
      subject do
        described_class.create.tap do |cgw|
          cgw.staff_note = staff_note
        end
      end
      its(:staff_note) { is_expected.to eq staff_note }
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

  describe "#legacy_identifier" do
    subject { described_class.new }
    let(:legacy_identifier) { ['ETDs'] }

    context "with new CurateGenericWork work" do
      its(:legacy_identifier) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a legacy_identifier" do
      subject do
        described_class.create.tap do |cgw|
          cgw.legacy_identifier = legacy_identifier
        end
      end
      its(:legacy_identifier) { is_expected.to eq legacy_identifier }
    end
  end

  describe "#legacy_ark" do
    subject { described_class.new }
    let(:legacy_ark) { ['Emory Legacy Ark'] }

    context "with new CurateGenericWork work" do
      its(:legacy_ark) { is_expected.to be_empty }
    end

    context "with a CurateGenericWork work that has a legacy_ark" do
      subject do
        described_class.create.tap do |cgw|
          cgw.legacy_ark = legacy_ark
        end
      end
      its(:legacy_ark) { is_expected.to eq legacy_ark }
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
end
