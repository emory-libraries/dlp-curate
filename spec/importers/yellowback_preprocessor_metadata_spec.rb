# frozen_string_literal: true
require 'rails_helper'

# rubocop:disable Style/LineEndConcatenation

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
    expect(import_rows[0]['title']).to eq('Edge cases : miscellaneous & sundry') # Edge cases
    expect(import_rows[1]['title']).to eq('Shakespeare\'s comedy of The merchant of Venice') # Shakespeare's comedy of The merchant of Venice
    expect(import_rows[2]['title']).to eq('Choice bits from Mark Twain.') # Choice bits from Mark Twain
    expect(import_rows[3]['title']).to eq('The common moths of England [Copy 2]') # The common moths of England
    expect(import_rows[4]['title']).to eq('The common moths of England [Copy 3]') # The common moths of England
  end

  # make sure we account for the header row
  # and that ruby starts counting from 0 while spreadsheets start with row 1
  it 'identifies the source row from the pull list' do
    expect(import_rows[1]['pl_row']).to eq('3') # Shakespeare's comedy of The merchant of Venice
  end

  it 'maps the ark as the unique work_id' do
    expect(import_rows[1]['work_id']).to eq('7stsg') # Shakespeare's comedy of The merchant of Venice
  end

  it 'correctly assigns work_id for mulitple volumes' do # The common moths of England
    expect(import_rows[3]['work_id']).to eq('7st4v') # copy 2
    expect(import_rows[4]['work_id']).to eq('7st50') # copy 2
  end

  # Pull List tests ############################################
  # fields that are extracted and mapped from the Pull List CSV
  it 'extracts administrative_unit values from the pull list' do
    expect(import_rows[1]['administrative_unit']).to eq('Stuart A. Rose Manuscript, Archives, and Rare Book Library') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts content_type URIs from the pull list' do
    expect(import_rows[1]['content_type']).to eq('http://id.loc.gov/vocabulary/resourceTypes/txt') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts data_classifications values from the pull list' do
    expect(import_rows[1]['data_classifications']).to eq('Confidential') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts the emory_ark from the pull list' do
    expect(import_rows[1]['emory_ark']).to eq('7stsg') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts emory_rights_statements values from the pull list' do
    expect(import_rows[1]['emory_rights_statements']).to match(/^The online edition of this book in the public domain.../) # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts holding_repository from the pull list' do
    expect(import_rows[1]['holding_repository']).to eq('Stuart A. Rose Manuscript, Archives, and Rare Book Library') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts institution values from the pull list' do
    expect(import_rows[1]['institution']).to eq('Emory University') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts the other_identifiers from the pull list' do
    expect(import_rows[1]['other_identifiers']).to eq('oclc:ocm04416480|' + # Shakespeare's comedy of The merchant of Venice
                                                      'barcode:010001355795|' +
                                                      'digwf:2987')
  end

  it 'extracts rights_statement URI values from the pull list' do
    expect(import_rows[1]['rights_statement']).to eq('http://rightsstatements.org/vocab/NoC-US/1.0/') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts the system_of_record_ID from the pull list' do
    expect(import_rows[1]['system_of_record_ID']).to eq('alma:990024722450302486') # Shakespeare's comedy of The merchant of Venice
  end

  # Alma tests ###############################################
  # Fields that are extracted and mapped from MARCXml records
  it 'extracts conference_name from Alma' do
    expect(import_rows[0]['conference_name']).to eq('International Exhibition (1862 : London, England)') # Edge cases
  end

  it 'extracts copyright_date from Alma' do
    expect(import_rows[1]['copyright_date']).to eq('1898') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts contributor information from Alma' do
    expect(import_rows[1]['contributor']).to eq('Gollancz, Israel, 1864-1930.|' + # Shakespeare's comedy of The merchant of Venice
                                                'Hughes, Ted, 1930-1998, former owner. GEU|' +
                                                'Ted Hughes Library (Emory University. General Libraries) GEU')
  end

  it 'extracts creator information from Alma' do
    expect(import_rows[1]['creator']).to eq('Shakespeare, William, 1564-1616.') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts date_created from Alma' do
    expect(import_rows[1]['date_created']).to eq('1898') # Shakespeare's comedy of The merchant of Venice
  end

  it 'sets date_created to XXXX when no date is specified' do
    expect(import_rows[0]['date_created']).to eq('XXXX') # Edge Cases
  end

  it 'extracts date_digitized from Alma' do
    expect(import_rows[1]['date_digitized']).to eq('2009') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts date_issued from Alma' do
    expect(import_rows[1]['date_issued']).to eq('1898') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts edition from Alma' do
    expect(import_rows[1]['edition']).to eq('5th edition.') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts extent from Alma' do
    expect(import_rows[3]['extent']).to eq('154 pages, 12 leaves of plates : illustrations ; 17 cm.') # The common moths of England
  end

  it 'extracts genre from Alma' do
    expect(import_rows[2]['genre']).to eq('Yellowbacks.') # Choice bits from Mark Twain
  end

  it 'leaves genre blank if no value exists Alma' do
    expect(import_rows[1]['genre']).to be_nil # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts local_call_number from Alma' do
    expect(import_rows[4]['local_call_number']).to eq('QL555.G7 W85') # The common moths of England
  end

  it 'extracts primary_language from Alma' do
    expect(import_rows[1]['primary_language']).to eq('eng') # Shakespeare's comedy of The merchant of Venice
  end

  it 'extracts publisher from Alma' do
    expect(import_rows[1]['publisher']).to eq('J.M. Dent') # Shakespeare's comedy of The merchant of Venice
  end

  it 'handles multiple publisher entries' do
    expect(import_rows[0]['publisher']).to eq('Chatto & Windus, Piccadilly|Printed by William Clowes and Sons, Limited') # Edge Cases
  end

  it 'extracts place_of_production from Alma' do
    expect(import_rows[1]['place_of_production']).to eq('London') # Shakespeare's comedy of The merchant of Venice
  end

  it 'handles multiple place_of_production entries' do
    expect(import_rows[0]['place_of_production']).to eq('London|London and Beccles') # Edge Cases
  end

  it 'extracts table_of_contents from Alma' do
    expect(import_rows[2]['table_of_contents']).to match(/^Autobiography -- Memoranda -- The facts in the case .../) # Choice bits from Mark Twain
  end

  it 'extracts titles from Alma' do
    expect(import_rows[1]['title']).to eq('Shakespeare\'s comedy of The merchant of Venice')
  end

  it 'extracts only subfields (a) and (b) from titles' do
    expect(import_rows[0]['title']).to eq('Edge cases : miscellaneous & sundry')
  end

  it 'handles character encodings correctly' do
    expect(import_rows[0]['uniform_title']).to eq('Belle geôlière.') # Edge cases
  end

  it 'extracts uniform_title from Alma' do
    expect(import_rows[2]['uniform_title']).to eq('Works.') # Choice bits from Mark Twain.
  end

  it 'extracts series_title from Alma' do
    expect(import_rows[0]['series_title']).to eq('Routledge\'s railway library.|' + # Edge cases
                                                   'Jarrolds\' railway library.')
  end

  it 'extracts subject_geo from Alma' do
    expect(import_rows[0]['subject_geo']).to eq('London (England)--Fiction.') # Edge cases
  end

  it 'extracts subject_names from Alma' do
    expect(import_rows[0]['subject_names']).to eq('Mary, Queen of Scots, 1542-1587|' + # Edge cases
                                                   'Bothwell, James Hepburn, Earl of, 1536?-1578')
  end

  it 'extracts subject_topics from Alma' do
    expect(import_rows[0]['subject_topics']).to eq('Aristocracy (Social class)--Fiction.|' + # Edge cases
                                                    'Upper class families--Fiction.|' +
                                                    'Dandies--Fiction.')
  end
end
