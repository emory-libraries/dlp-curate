# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Importing preprocessed langmuir', :clean, perform_enqueued: [AttachFilesToWorkJob, IngestJob], type: :system do
  let(:modular_csv) { 'spec/fixtures/csv_import/good/langmuir_post_processing.csv' }
  let(:user) { ::User.batch_user }
  let(:collection) { FactoryBot.build(:collection_lw) }
  let(:csv_import) do
    import = Zizia::CsvImport.new(user: user, fedora_collection_id: collection.id)
    File.open(modular_csv) { |f| import.manifest = f }
    import
  end
  let(:importer) { ModularImporter.new(csv_import) }

  before(:all) do
    ENV['IMPORT_PATH'] = File.join(fixture_path, 'fake_images')
  end

  context 'after running an import' do
    it 'has 4 CurateGenericWorks' do
      importer.import
      expect(CurateGenericWork.count).to eq(4)
      expect(FileSet.count).to eq(8)
      expect(CurateGenericWork.first.file_sets.size).to eq(2)
      expect(CurateGenericWork.first.ordered_members.to_a.first.title).to eq(['Front'])
      expect(CurateGenericWork.first.ordered_members.to_a.last.title).to eq(['Back'])
      expect(CurateGenericWork.first.representative.title).to eq(['Front'])
      expect(CurateGenericWork.last.representative.title).to eq(['Front'])
      visit('/')
    end
  end
end
