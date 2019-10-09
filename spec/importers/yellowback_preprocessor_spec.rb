# frozen_string_literal: true
require 'rails_helper'

RSpec.describe YellowbackPreprocessor do
  before :all do
    # running #merge is expensive, only set it up and run it once and then check the results
    yellowback_pull_list_sample = File.join(fixture_path, 'csv_import', 'yellowbacks', 'yellowbacks_pull_list.csv')
    alma_export_sample = File.join(fixture_path, 'csv_import', 'yellowbacks', 'yellowbacks_marc.xml')
    preprocessor = described_class.new(yellowback_pull_list_sample, alma_export_sample)
    preprocessor.merge
  end

  after :all do
    test_csv = File.join(fixture_path, 'csv_import', 'yellowbacks', 'yellowbacks_pull_list-merged.csv')
    File.delete(test_csv) if File.exist?(test_csv)
  end

  # each test inspects the output of the pre-processor, read into the import_rows CSV::Table object
  let(:import_rows) { CSV.read(File.join(fixture_path, 'csv_import', 'yellowbacks', 'yellowbacks_pull_list-merged.csv'), headers: true).by_row! }

  it 'processes the expected number of rows' do
    expect(import_rows.length).to eq(5)
  end

  # this just repeats the csv data, but shows the testing pattern and titles used in subsequent tests
  it 'processes the expected works' do
    expect(import_rows[0]['title']).to eq('Edge cases') # Edge cases
    expect(import_rows[1]['title']).to eq('Shakespeare\'s comedy of The merchant of Venice /') # Shakespeare's comedy of The merchant of Venice
    expect(import_rows[2]['title']).to eq('Choice bits from Mark Twain.') # Choice bits from Mark Twain
    expect(import_rows[3]['title']).to eq('The common moths of England /') # The common moths of England
    expect(import_rows[4]['title']).to eq('The common moths of England /') # The common moths of England
  end

  # make sure we account for the header row
  # and that ruby starts counting from 0 while spreadsheets start with row 1
  it 'identifies the source row from the pull list' do
    expect(import_rows[1]['pl_row']).to eq('3') # Shakespeare's comedy of The merchant of Venice
  end

  it 'maps the ark as the unique work_id' do
    expect(import_rows[1]['work_id']).to eq('7stsg') # Shakespeare's comedy of The merchant of Venice
  end
end
