# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurateRecordImporter do
  subject(:importer) { described_class.new(attributes: { csv_import_detail: fake_import_detail }) }
  let(:fake_import_detail) { FactoryBot.build(:csv_import_detail) }

  it 'constructs the correct path for files' do
    cached_import_path = ENV['IMPORT_PATH']
    ENV['IMPORT_PATH'] = '/MOUNT_POINT/ROOT_PATH/'

    absolute_file_path = importer.find_file_path('dmfiles/MARBL/Manuscripts/MSS_1218_Langmuir/PROD/OP/MSS1218_OP1_P0001_PROD.tif')
    expected_file_path = '/MOUNT_POINT/ROOT_PATH/dmfiles/MARBL/Manuscripts/MSS_1218_Langmuir/PROD/OP/MSS1218_OP1_P0001_PROD.tif'
    expect(absolute_file_path).to eq(expected_file_path)

    ENV['IMPORT_PATH'] = cached_import_path
  end

  it 'returns an empty string if a filename is missing' do
    expect(importer.find_file_path(nil)).to eq('')
  end
end
