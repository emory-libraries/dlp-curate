# frozen_string_literal: true
# [Hydra-works-overwrite]
require 'rails_helper'
require 'support/file_set_helper'

describe Hydra::Works::CharacterizationService, :clean do
  describe "integration test for characterizing from path on disk." do
    let(:filename)     { 'sample-file.pdf' }
    let(:path_on_disk) { File.join(fixture_path, filename) }
    let(:file)         { Hydra::PCDM::File.new }

    before do
      skip 'external tools not installed for CI environment' if ENV['CI']
      described_class.run(file, path_on_disk)
    end

    it 'successfully sets the property values' do
      expect(file.file_size).to eq(["7618"])
      expect(file.file_title).to eq(["sample-file"])
      expect(file.page_count).to eq(["1"])
      # Persist our file with some content and reload
      file.content = "junk"
      expect(file.save).to be true
      expect(file.reload).to eq({})
      # Re-check property values
      expect(file.file_size).to eq(["7618"])
      expect(file.file_title).to eq(["sample-file"])
      expect(file.page_count).to eq(["1"])
    end
  end

  describe "handling strings, files, and Hydra::PCDM::File as sources" do
    # Stub Hydra::FileCharacterization.characterize
    let(:characterization)   { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:fits_filename)      { 'fits_1.4.0_sample_pdf.xml' }
    let(:fits_response)      { IO.read(File.join(fixture_path, fits_filename)) }
    let(:filename)           { 'sample-file.pdf' }
    let(:file_content)       { IO.read(File.join(fixture_path, filename)) }
    let(:file)               { Hydra::PCDM::File.new { |f| f.content = file_content } }
    let(:digest)             { class_double("Digest::SHA256").as_stubbed_const }
    let(:hexdigest_value)    { "urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a" }

    before do
      allow(characterization).to receive(:characterize).and_return(fits_response)
      allow(digest).to receive_message_chain(:file, :hexdigest, :prepend).and_return(hexdigest_value)
    end

    context "with the object as the source" do
      it 'calls the content method of the object.' do
        expect(file).to receive(:content)
        described_class.run(file)
      end

      context "when original_name is not present" do
        it 'passes the content to characterization.' do
          expect(Hydra::FileCharacterization).to receive(:characterize).with(file_content, "original_file", :fits)
          described_class.run(file)
        end
      end

      context "when original_name is present" do
        before { allow(file).to receive(:original_name).and_return(filename) }
        it 'passes the content to characterization.' do
          expect(Hydra::FileCharacterization).to receive(:characterize).with(file_content, filename, :fits)
          described_class.run(file)
        end
      end
    end

    context "using a string path as the source." do
      it 'passes a file with the string as a path to FileCharacterization.' do
        path_on_disk = File.join(fixture_path, filename)
        expect(Hydra::FileCharacterization).to receive(:characterize).with(kind_of(File), filename, :fits)
        described_class.run(file, path_on_disk)
      end
    end

    context "using a File instance as the source." do
      it 'passes the File to FileCharacterization.' do
        file_inst = File.new(File.join(fixture_path, filename))
        expect(Hydra::FileCharacterization).to receive(:characterize).with(file_content, filename, :fits)
        expect(file_inst).to receive(:rewind)
        described_class.run(file, file_inst)
      end
    end
  end

  context "passing an object that does not have matching properties" do
    let(:characterization) { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:fits_filename)    { 'fits_1.4.0_sample_pdf.xml' }
    let(:fits_response)    { IO.read(File.join(fixture_path, fits_filename)) }
    let(:file_content)     { 'dummy content' }
    let(:file)             { Hydra::PCDM::File.new { |f| f.content = file_content } }
    let(:digest)           { class_double("Digest::SHA256").as_stubbed_const }
    let(:hexdigest_value)  { "urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a" }

    around do |example|
      @current_schemas = ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas
      @metadata_schema = Hydra::PCDM::File::GeneratedMetadataSchema
      ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas = [ActiveFedora::WithMetadata::DefaultSchema]
      example.run
      ActiveFedora::WithMetadata::DefaultMetadataClassFactory.file_metadata_schemas = @current_schemas
      # This next line required to force resetting the metadata schema class used by Hydra::PCDM::File
      Hydra::PCDM::File.instance_variable_set(:@metadata_schema, @metadata_schema)
    end

    before do
      allow(characterization).to receive(:characterize).and_return(fits_response)
      allow(digest).to receive_message_chain(:file, :hexdigest, :prepend).and_return(hexdigest_value)
    end

    it 'does not explode with an error' do
      expect { described_class.run(file) }.not_to raise_error
    end
  end

  describe 'assigned properties.' do
    # Stub Hydra::FileCharacterization.characterize
    let(:characterization) { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:file)             { Hydra::PCDM::File.new }
    let(:digest)           { class_double("Digest::SHA256").as_stubbed_const }
    let(:hexdigest_value)  { "urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a" }

    before do
      allow(file).to receive(:content).and_return("mocked content")
      allow(characterization).to receive(:characterize).and_return(fits_response)
      allow(digest).to receive_message_chain(:file, :hexdigest, :prepend).and_return(hexdigest_value)

      described_class.run(file)
    end

    context 'using document metadata' do
      let(:fits_filename) { 'fits_1.4.0_sample_pdf.xml' }
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      it 'assigns expected values to document properties.' do
        expect(file.file_title).to eq(["sample-file"])
        expect(file.page_count).to eq(["1"])
      end
    end

    context 'using netCDF metadata' do
      let(:fits_filename) { 'fits_netcdf_two_mimetypes.xml' }
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      it 'reports the correct, single MIME type' do
        expect(file.mime_type).to eq("application/netcdf")
      end
    end

    context 'using image metadata' do
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      context 'with fits_1.4.0' do
        let(:fits_filename) { 'fits_1.4.0_image_jp2.xml' }
        it 'assigns expected values to image properties.' do
          expect(file.file_size).to eq(["11043"])
          expect(file.byte_order).to eq(["big endian"])
          expect(file.compression).to contain_exactly("JPEG 2000 Lossless", "JPEG 2000")
          expect(file.width).to eq(["512"])
          expect(file.height).to eq(["465"])
          expect(file.color_space).to eq(["sRGB"])
        end
      end

      context 'with fits_1.2.0' do
        let(:fits_filename) { 'fits_1.2.0_jpg.xml' }
        it 'ensures duplicate values are not returned for exifVersion, dateCreated, dateModified.' do
          expect(file.exif_version).to eq(["0221"])
          expect(file.date_created).to eq(["2009:02:04 11:05:25.36-06:00"])
          expect(file.date_modified).to eq(["2009:02:04 16:10:47"])
        end
      end
    end

    context 'using video metadata' do
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      context 'with fits_1.4.0' do
        let(:fits_filename) { 'fits_1.4.0_countdown_avi.xml' }
        it 'assigns expected values to video properties.' do
          expect(file.height).to eq(["264"])
          expect(file.width).to eq(["356"])
          expect(file.duration).to eq(["14148"])
          expect(file.frame_rate).to eq(["10.000"])
          expect(file.bit_rate).to eq(["409204"])
          expect(file.aspect_ratio).to eq(["4:3"])
        end
      end
    end

    context 'using audio metadata' do
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      context 'with fits_1.4.0' do
        let(:fits_filename) { 'fits_1.4.0_test5_mp3.xml' }
        it 'assigns expected values to audio properties.' do
          expect(file.mime_type).to eq("audio/mpeg")
          expect(file.duration).to eq(["0:0:15:261"])
          expect(file.bit_rate).to include("192000")
          expect(file.sample_rate).to eq(["44100"])
        end
      end
    end

    context 'using multi-layer tiff metadata' do
      let(:fits_filename) { 'fits_1.4.0_test_tiff.xml' }
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }

      it 'assigns single largest value to width, height' do
        expect(file.width).to eq(["800"])
        expect(file.height).to eq(["600"])
      end
    end
  end

  describe 'assigned properties from fits 1.4.0' do
    # Stub Hydra::FileCharacterization.characterize
    let(:characterization) { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:digest)           { class_double("Digest::SHA256").as_stubbed_const }
    let(:file)             { Hydra::PCDM::File.new }

    context 'using image metadata' do
      let(:fits_filename) { 'fits_1.4.0_cat_jpeg.xml' }
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }
      let(:hexdigest_value) { "urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a" }
      before do
        allow(file).to receive(:content).and_return("mocked content")
        allow(characterization).to receive(:characterize).and_return(fits_response)
        allow(digest).to receive_message_chain(:file, :hexdigest, :prepend).and_return(hexdigest_value)
        described_class.run(file)
      end
      it 'assigns expected values to image properties.' do
        expect(file.file_size).to eq(["3448"])
        expect(file.byte_order).to eq(["big endian"])
        expect(file.compression).to eq(["JPEG"])
        expect(file.width).to eq(["112"])
        expect(file.height).to eq(["130"])
        expect(file.color_space).to eq(["YCbCr"])
      end
    end

    # Tests for technical metadata that we added in curate_file_schema.rb
    context 'using pdf metadata' do
      let(:fits_filename) { 'fits_1.4.0_sample_pdf.xml' }
      let(:fits_response) { IO.read(File.join(fixture_path, fits_filename)) }
      let(:hexdigest_value) { "urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a" }
      before do
        allow(file).to receive(:content).and_return("mocked content")
        allow(characterization).to receive(:characterize).and_return(fits_response)
        allow(digest).to receive_message_chain(:file, :hexdigest, :prepend).and_return(hexdigest_value)
        described_class.run(file)
      end
      it 'assigns expected values to pdf properties' do
        expect(file.puid).to eq(["fmt/17"])
        expect(file.creating_application_name).to eq(["Mac OS X 10.10.3 Quartz PDFContext/TextEdit"])
        expect(file.file_path).to eq(["/Users/dmatlaw/Downloads/sample-file.pdf"])
        expect(file.original_checksum).to include("urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a")
        expect(file.original_checksum).to include("urn:md5:3a1735b5b30c4adc3f92c70004ae53ed")
      end
    end
  end

  describe 'preservation event for message digest' do
    let(:characterization) { class_double("Hydra::FileCharacterization").as_stubbed_const }
    let(:user)             { FactoryBot.create(:user) }
    let(:file_set)         { FactoryBot.create(:file_set, user: user, title: ['Some title']) }
    let(:filename)         { 'sample-file.pdf' }
    let(:path_on_disk)     { File.join(fixture_path, filename) }
    let(:file)             { File.open(path_on_disk) }
    let(:fits_filename)    { 'fits_1.4.0_sample_pdf.xml' }
    let(:fits_response)    { IO.read(File.join(fixture_path, fits_filename)) }
    let(:digest)           { class_double("Digest::SHA256").as_stubbed_const }
    let(:hexdigest_value)  { "urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a" }

    before do
      Hydra::Works::AddFileToFileSet.call(file_set, file, :preservation_master_file)
      allow(characterization).to receive(:characterize).and_return(fits_response)
    end

    context 'with all three checksums present' do
      before do
        allow(digest).to receive_message_chain(:file, :hexdigest, :prepend).and_return(hexdigest_value)
        described_class.run(file_set.preservation_master_file, path_on_disk)
        file_set.reload
      end

      it 'creates a success preservation event on fileset' do
        expect(file_set.preservation_event.pluck(:event_type)).to include ['Message Digest Calculation']
        expect(file_set.preservation_event.pluck(:event_details)).to include ["urn:sha1:efdadf049446295f4bd6e73e2a79dd114c4f4791",
                                                                              "urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a",
                                                                              "urn:md5:3a1735b5b30c4adc3f92c70004ae53ed"]
        expect(file_set.preservation_event.pluck(:initiating_user)).to include [user.uid]
        expect(file_set.preservation_event.pluck(:outcome)).to include ['Success']
      end
    end

    context 'with one checksum missing' do
      before do
        allow(digest).to receive_message_chain(:file, :hexdigest, :prepend)
        described_class.run(file_set.preservation_master_file, path_on_disk)
        file_set.reload
      end

      it 'creates a failure preservation event on fileset' do
        expect(file_set.preservation_event.pluck(:event_type)).to include ['Message Digest Calculation']
        expect(file_set.preservation_event.pluck(:event_details)).not_to include 'urn:sha256:9f08fe67e102fc94950070cf5de88ba760846516daf2c76a1167c809ec37b37a'
        expect(file_set.preservation_event.pluck(:outcome)).to include ['Failure']
      end
    end
  end
end
