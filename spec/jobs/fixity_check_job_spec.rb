# frozen_string_literal: true
# [Hyrax-overwrite]
# Adds tests for fixity_check preservation_event
require 'rails_helper'

RSpec.describe FixityCheckJob, :clean do
  let(:user) { FactoryBot.create(:user) }

  let(:file_set) do
    FactoryBot.create(:file_set, user: user).tap do |file|
      Hydra::Works::AddFileToFileSet.call(file, File.open(fixture_path + '/world.png'), :preservation_master_file, versioning: true)
    end
  end
  let(:file_id) { file_set.preservation_master_file.id }

  describe "called with perform_now" do
    let(:log_record) { described_class.perform_now(uri, file_set_id: file_set.id, file_id: file_id) }

    describe 'fixity check the content' do
      let(:uri) { file_set.preservation_master_file.uri }

      it 'passes' do
        expect(log_record).to be_passed
      end
      it "returns a ChecksumAuditLog" do
        expect(log_record).to be_kind_of ChecksumAuditLog
        expect(log_record.checked_uri).to eq uri
        expect(log_record.file_id).to eq file_id
        expect(log_record.file_set_id).to eq file_set.id
      end
    end

    describe 'fixity check a version of the content' do
      let(:uri) { Hyrax::VersioningService.latest_version_of(file_set.preservation_master_file).uri }

      it 'passes' do
        expect(log_record).to be_passed
      end
      it "returns a ChecksumAuditLog" do
        expect(log_record).to be_kind_of ChecksumAuditLog
      end
    end

    describe 'fixity check an invalid version of the content' do
      let(:uri) { Hyrax::VersioningService.latest_version_of(file_set.preservation_master_file).uri + 'bogus' }

      it 'fails' do
        expect(log_record).to be_failed
      end
      it "returns a ChecksumAuditLog" do
        expect(log_record).to be_kind_of ChecksumAuditLog
      end
    end

    describe 'creates fixity_check preservation_events' do
      let(:file1) { File.open(fixture_path + '/sun.png') }
      let(:file2) { File.open(fixture_path + '/image.jp2') }
      let(:uri1)  { file_set.preservation_master_file.uri }
      let(:uri2)  { file_set.service_file.uri }
      let(:uri3)  { file_set.intermediate_file.uri }

      before do
        Hydra::Works::AddFileToFileSet.call(file_set, file1, :service_file)
        Hydra::Works::AddFileToFileSet.call(file_set, file2, :intermediate_file)
        described_class.perform_now(uri1, file_set_id: file_set.id, file_id: file_set.preservation_master_file.id)
        described_class.perform_now(uri2, file_set_id: file_set.id, file_id: file_set.service_file.id)
      end

      context 'when all fixity_checks pass for a file_set' do
        before do
          described_class.perform_now(uri3, file_set_id: file_set.id, file_id: file_set.intermediate_file.id)
          file_set.reload
        end

        it 'creates three success fixity_check preservation_events' do
          expect(file_set.preservation_event.pluck(:event_details)).to include ["Fixity intact for file: world.png: sha1:#{file_set.preservation_master_file.checksum.value}"]
          expect(file_set.preservation_event.pluck(:event_details)).to include ["Fixity intact for file: sun.png: sha1:#{file_set.preservation_master_file.checksum.value}"]
          expect(file_set.preservation_event.pluck(:event_details)).to include ["Fixity intact for file: image.jp2: sha1:#{file_set.preservation_master_file.checksum.value}"]
        end
      end

      context 'when fixity_check fails for a file' do
        let(:cal) { ChecksumAuditLog.create!(passed: false, file_set_id: file_set.id, file_id: file_set.intermediate_file.id) }
        before do
          allow(ChecksumAuditLog).to receive(:create_and_prune!).and_return(cal)
          described_class.perform_now(uri3, file_set_id: file_set.id, file_id: file_set.intermediate_file.id)
          file_set.reload
        end

        it 'creates one failure and two success fixity_check preservation_events' do
          expect(file_set.preservation_event.pluck(:event_details)).to include ["Fixity check failed for: image.jp2: sha1:#{file_set.preservation_master_file.checksum.value}"]
          expect(file_set.preservation_event.pluck(:event_details)).to include ["Fixity intact for file: world.png: sha1:#{file_set.preservation_master_file.checksum.value}"]
          expect(file_set.preservation_event.pluck(:event_details)).to include ["Fixity intact for file: sun.png: sha1:#{file_set.preservation_master_file.checksum.value}"]
        end
      end
    end
  end
end
