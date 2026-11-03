# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PreprocessorModelNames do
  subject(:names) { Class.new { include PreprocessorModelNames }.new }

  context 'during the Valkyrie transition' do
    before { allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true) }

    it 'names the Valkyrie models' do
      expect(names.work_model_name).to eq 'CurateGenericWorkResource'
      expect(names.file_set_model_name).to eq 'FileSetResource'
    end
  end

  context 'without the Valkyrie transition' do
    before { allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(false) }

    it 'names the ActiveFedora models' do
      expect(names.work_model_name).to eq 'CurateGenericWork'
      expect(names.file_set_model_name).to eq 'FileSet'
    end
  end

  # Each preprocessor writes its output next to its input CSV, so run it on a copy.
  describe 'preprocessed CSVs during the Valkyrie transition' do
    let(:models) { CSV.read(processed_csv, headers: true).map { |row| row['model'] }.uniq }

    around do |example|
      Dir.mktmpdir do |dir|
        @tmp_dir = dir
        example.run
      end
    end

    before { allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true) }

    def copy_fixture(*path)
      FileUtils.cp(File.join(fixture_path, 'csv_import', *path), @tmp_dir)
      File.join(@tmp_dir, path.last)
    end

    context 'with DamsPreprocessor' do
      let(:processed_csv) { File.join(@tmp_dir, 'dams-unprocessed-processed.csv') }

      it 'uses the Valkyrie model names' do
        DamsPreprocessor.new(copy_fixture('dams', 'dams-unprocessed.csv')).merge

        expect(models).to contain_exactly('CurateGenericWorkResource', 'FileSetResource')
      end
    end

    context 'with LangmuirPreprocessor' do
      let(:processed_csv) { File.join(@tmp_dir, 'langmuir-unprocessed-processed.csv') }

      it 'uses the Valkyrie model names' do
        LangmuirPreprocessor.new(copy_fixture('langmuir', 'langmuir-unprocessed.csv')).merge

        expect(models).to contain_exactly('CurateGenericWorkResource', 'FileSetResource')
      end
    end

    context 'with YellowbackPreprocessor' do
      let(:processed_csv) { File.join(@tmp_dir, 'yellowbacks_pull_list-merged.csv') }

      it 'uses the Valkyrie model names' do
        marc = File.join(fixture_path, 'csv_import', 'yellowbacks', 'yellowbacks_marc.xml')
        YellowbackPreprocessor.new(copy_fixture('yellowbacks', 'yellowbacks_pull_list.csv'), marc).merge

        expect(models).to contain_exactly('CurateGenericWorkResource', 'FileSetResource')
      end
    end
  end
end
