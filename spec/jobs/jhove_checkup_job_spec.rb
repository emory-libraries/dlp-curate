# frozen_string_literal: true
require 'rails_helper'

RSpec.describe JhoveCheckupJob, :clean do
  Sidekiq.logger.level = Logger::WARN
  let(:csv_path)       { File.join("config/emory/problem_files.csv") }
  let(:csv)            { IO.read(csv_path) }
  let(:good_xml)       { File.read(fixture_path + '/jhove_check_xml/well_formatted.xml') }
  let(:bad_xml)        { File.read(fixture_path + '/jhove_check_xml/not_well_formatted.xml') }
  let(:good_file_path) { "/Users/dmatlaw/rails_apps/dlp-curate/spec/fixtures/book_page/0003_preservation_master.tif" }
  let(:bad_file_path)  { "/Users/dmatlaw/Downloads/jhove-1.24.1/jhove-core/src/main/examples/tiff/libtiff_v3/smallliz.tif" }

  after do
    File.delete(csv_path) if File.exist?(csv_path)
  end

  context 'with a good and bad file' do
    let(:jhove_command_bad)  { "some_jhove_path -m TIFF-hul -h XML #{bad_file_path}" }
    let(:jhove_command_good) { "some_jhove_path -m TIFF-hul -h XML #{good_file_path}" }
    before do
      allow(Open3).to receive(:capture3).with(jhove_command_good).and_return(good_xml, "", "")
      allow(Open3).to receive(:capture3).with(jhove_command_bad).and_return(bad_xml, "", "")
      allow(Dir).to receive(:glob).and_return([good_file_path, bad_file_path])
      described_class.perform_now("some_jhove_path", "fixture_path")
    end

    it 'adds bad filepath to csv but does not add good file' do
      expect(csv).not_to include(good_file_path)
      expect(csv).to include(bad_file_path)
    end
  end
end
