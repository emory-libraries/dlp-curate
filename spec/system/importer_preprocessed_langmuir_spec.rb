# frozen_string_literal: true

require 'rails_helper'

# Deprecation Warning: As of Curate v3, Zizia and this spec will be removed.
RSpec.describe 'Importing preprocessed langmuir', perform_enqueued: [AttachFilesToWorkJob, IngestJob], type: :system do
  let(:modular_csv) { 'spec/fixtures/csv_import/good/langmuir_post_processing.csv' }
  let(:user) { ::User.batch_user }
  let(:collection) { FactoryBot.build(:collection_lw) }
  let(:csv_import) do
    import = Zizia::CsvImport.new(user: user, fedora_collection_id: collection.id)
    File.open(modular_csv) { |f| import.manifest = f }
    import
  end
  let(:importer) { ModularImporter.new(csv_import) }
  let(:test_hash) do
    {
      "access_restriction_notes" => "Don't show this to anyone.",
      "author_notes" => "Written while intoxicated.",
      "conference_dates" => "2015-01-08 TO 2015-01-13",
      "data_collection_dates" => "2020-01-01",
      "data_producers" => "Petrol",
      "data_source_notes" => "Off the floor of a bathroom.",
      "final_published_versions" => "https://www.someboguswebsite.gov",
      "geographic_unit" => "Florida",
      "grant_agencies" => "ASCAP",
      "grant_information" => "$1,000,000",
      "isbn" => "17728891-6",
      "issn" => "105-196-560",
      "issue" => "260",
      "page_range_end" => "200",
      "page_range_start" => "15",
      "parent_title" => "An older, wiser title",
      "primary_repository_ID" => nil,
      "publisher_version" => "Post-print, After Peer Review",
      "related_datasets" => "https://www.someboguswebsite.gov",
      "related_material_notes" => "Some pages are stained.",
      "related_publications" => "https://www.someboguswebsite.gov",
      "re_use_license" => "https://creativecommons.org/licenses/by/4.0/",
      "rights_documentation" => "https://www.someboguswebsite.gov",
      "scheduled_rights_review" => "2021-01-02",
      "scheduled_rights_review_note" => "Rip it off the site.",
      "sponsor" => "Shell Oil",
      "staff_notes" => "Got this one done.",
      "subject_time_periods" => "Medieval Times",
      "technical_note" => "Use a Mac.",
      "volume" => "10"
    }
  end
  before(:all) do
    ENV['IMPORT_PATH'] = File.join(fixture_path, 'fake_images')
  end

  context 'after running an import' do
    it 'has 5 CurateGenericWorks' do
      importer.import
      expect(CurateGenericWork.count).to eq(5)
      expect(FileSet.count).to eq(12)
      expect(FileSet.all.map(&:pcdm_use)).to include('Primary Content', 'Supplemental Content', 'Supplemental Preservation')
      expect(CurateGenericWork.first.file_sets.size).to eq(2)
      expect(CurateGenericWork.first.ordered_members.to_a.first.title).to eq(['Front'])
      expect(CurateGenericWork.first.ordered_members.to_a.last.title).to eq(['Back'])
      expect(CurateGenericWork.first.representative.title).to eq(['Front'])
      expect(CurateGenericWork.where(title: '*frisky*').first.representative.title).to eq(['Side 1'])
      expect(CurateGenericWork.where(title: '*frisky*').first.ordered_members.to_a.last.title).to eq(['Side 4'])
      expect(Zizia::PreIngestWork.count).to eq(5)
      expect(Zizia::PreIngestFile.count).to eq(60)
      expect(Zizia::PreIngestFile.last.row_number).to eq(18)
      expect(Zizia::PreIngestWork.last['deduplication_key']).to be_kind_of(String)
    end

    it 'has the new fields added' do
      importer.import
      work = CurateGenericWork.where(deduplication_key: 'MSS1218_B071_I205')

      test_hash.keys.each do |field|
        expect(work.first[field]).to eq(test_hash[field]).or eq([test_hash[field]])
      end
    end
  end
end
