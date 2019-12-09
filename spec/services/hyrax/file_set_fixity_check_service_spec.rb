# frozen_string_literal: true
# [Hyrax-overwrite]
# Adds tests for fixity_check preservation_events on L#94
require 'rails_helper'

RSpec.describe Hyrax::FileSetFixityCheckService do
  let(:f)                 { FactoryBot.create(:file_set) }
  let(:file)              { File.open(fixture_path + '/balloon.jpeg') }
  let(:service_by_object) { described_class.new(f) }
  let(:service_by_id)     { described_class.new(f.id) }

  describe "async_jobs: false" do
    let(:service_by_object) { described_class.new(f, async_jobs: false) }
    let(:service_by_id)     { described_class.new(f.id, async_jobs: false) }

    describe '#fixity_check' do
      subject :fixity_check do
        service_by_object.fixity_check
      end

      context 'when a file has two versions' do
        before do
          Hydra::Works::AddFileToFileSet.call(f, file, :preservation_master_file)
          Hyrax::VersioningService.create(f.preservation_master_file) # create a second version -- the factory creates the first version when it attaches +content+
        end
        specify 'returns two log results' do
          expect(fixity_check.values.flatten.length).to eq(2)
        end

        context "with latest_version_only" do
          let(:service_by_object) { described_class.new(f, async_jobs: false, latest_version_only: true) }

          specify "returns one log result" do
            expect(fixity_check.values.length).to eq(1)
          end
        end
      end

      context "existing check and disabled max_days_between_fixity_checks" do
        before do
          Hydra::Works::AddFileToFileSet.call(f, file, :preservation_master_file)
        end
        let(:service_by_object) { described_class.new(f, async_jobs: false, max_days_between_fixity_checks: -1) }
        let(:service_by_id)     { described_class.new(f.id, async_jobs: false, max_days_between_fixity_checks: -1) }
        let!(:existing_record) do
          ChecksumAuditLog.create!(passed: true, file_set_id: f.id, checked_uri: f.preservation_master_file.versions.first.label, file_id: f.preservation_master_file.id)
        end

        it "re-checks" do
          existing_record
          expect(fixity_check.length).to eq 1
          expect(fixity_check.values.flatten.first.id).not_to eq(existing_record.id)
          expect(fixity_check.values.flatten.first.created_at).to be > existing_record.created_at
        end
      end
    end

    describe '#fixity_check_file' do
      subject :fixity_check_file do
        service_by_object.send(:fixity_check_file, f.preservation_master_file)
      end

      specify 'returns a single result' do
        Hydra::Works::AddFileToFileSet.call(f, file, :preservation_master_file)
        expect(fixity_check_file.length).to eq(1)
      end
      describe 'non-versioned file with latest version only' do
        let(:service_by_object) { described_class.new(f, async_jobs: false, latest_version_only: true) }

        before do
          Hydra::Works::AddFileToFileSet.call(f, file, :preservation_master_file)
          allow(f.preservation_master_file).to receive(:has_versions?).and_return(false)
        end

        specify 'returns a single result' do
          expect(fixity_check_file.length).to eq(1)
        end
      end
    end

    describe '#fixity_check_file_version' do
      subject :fixity_check_file_version do
        service_by_object.send(:fixity_check_file_version, f.preservation_master_file.id, f.preservation_master_file.uri.to_s)
      end

      specify 'returns a single ChecksumAuditLog for the given file' do
        Hydra::Works::AddFileToFileSet.call(f, file, :preservation_master_file)
        expect(fixity_check_file_version).to be_kind_of ChecksumAuditLog
        expect(fixity_check_file_version.file_set_id).to eq(f.id)
        expect(fixity_check_file_version.checked_uri).to eq(f.preservation_master_file.uri)
      end
    end

    describe 'creates preservation_events' do
      let(:service_by_object) { described_class.new(f, async_jobs: false) }

      context 'when fixity check passes' do
        before do
          service_by_object.fixity_check
        end

        it 'creates success fixity_check preservation_event' do
          expect(f.preservation_event.pluck(:event_type)).to include ['Fixity Check']
          expect(f.preservation_event.pluck(:event_details)).to include ['Fixity intact for all files']
        end
      end

      context 'when fixity check fails' do
        let(:file1) { File.open(fixture_path + '/sun.png') }
        let(:file2) { File.open(fixture_path + '/image.jp2') }
        let(:cal)   { ChecksumAuditLog.create!(passed: false, file_set_id: f.id, file_id: f.preservation_master_file.id) }
        let(:cal1)  { ChecksumAuditLog.create!(passed: true, file_set_id: f.id, file_id: f.service_file.id) }
        let(:cal2)  { ChecksumAuditLog.create!(passed: false, file_set_id: f.id, file_id: f.intermediate_file.id) }

        before do
          Hydra::Works::AddFileToFileSet.call(f, file, :preservation_master_file)
          Hydra::Works::AddFileToFileSet.call(f, file1, :service_file)
          Hydra::Works::AddFileToFileSet.call(f, file2, :intermediate_file)
          allow(service_by_object).to receive(:fixity_check_file).with(f.preservation_master_file).and_return([cal])
          allow(service_by_object).to receive(:fixity_check_file).with(f.service_file).and_return([cal1])
          allow(service_by_object).to receive(:fixity_check_file).with(f.intermediate_file).and_return([cal2])
          service_by_object.fixity_check
        end

        it 'creates failure fixity_check preservation_event' do
          expect(f.preservation_event.pluck(:event_type)).to include ['Fixity Check']
          expect(f.preservation_event.pluck(:event_details)).to include ["Fixity check failed for: balloon.jpeg: sha1:#{f.preservation_master_file.checksum.value}"]
          expect(f.preservation_event.pluck(:event_details)).to include ["Fixity check failed for: image.jp2: sha1:#{f.intermediate_file.checksum.value}"]
          expect(f.preservation_event.pluck(:outcome)).to include ['Failure']
        end
      end
    end
  end
end
