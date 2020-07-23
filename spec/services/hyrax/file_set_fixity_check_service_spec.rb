# frozen_string_literal: true
# [Hyrax-overwrite-v3.0.0.pre.rc1]
require 'rails_helper'

RSpec.describe Hyrax::FileSetFixityCheckService, :clean do
  let(:f) do
    FactoryBot.create(:file_set).tap do |file|
      Hydra::Works::AddFileToFileSet.call(file, File.open(fixture_path + '/world.png'), :preservation_master_file, versioning: true)
    end
  end
  let(:user)              { FactoryBot.create(:user) }
  let(:service_by_object) { described_class.new(f, initiating_user: user.uid) }
  let(:service_by_id)     { described_class.new(f.id, initiating_user: user.uid) }

  describe "async_jobs: false" do
    let(:service_by_object) { described_class.new(f, async_jobs: false, initiating_user: user.uid) }
    let(:service_by_id)     { described_class.new(f.id, async_jobs: false, initiating_user: user.uid) }

    describe '#fixity_check' do
      subject(:check) { service_by_object.fixity_check }

      context 'when a file has two versions' do
        before do
          Hyrax::VersioningService.create(f.original_file) # create a second version -- the factory creates the first version when it attaches +content+
        end
        specify 'returns two log results' do
          expect(check.values.flatten.length).to eq(2)
        end

        context "with latest_version_only" do
          let(:service_by_object) { described_class.new(f, async_jobs: false, latest_version_only: true, initiating_user: user.uid) }

          specify "returns one log result" do
            expect(check.values.length).to eq(1)
          end
        end
      end

      context "existing check and disabled max_days_between_fixity_checks" do
        let(:service_by_object) { described_class.new(f, async_jobs: false, max_days_between_fixity_checks: -1, initiating_user: user.uid) }
        let(:service_by_id)     { described_class.new(f.id, async_jobs: false, max_days_between_fixity_checks: -1, initiating_user: user.uid) }
        let!(:existing_record) do
          ChecksumAuditLog.create!(passed: true, file_set_id: f.id, checked_uri: f.original_file.versions.first.label, file_id: f.original_file.id)
        end

        it "re-checks" do
          existing_record
          expect(check.length).to eq 1
          expect(check.values.flatten.first.id).not_to eq(existing_record.id)
          expect(check.values.flatten.first.created_at).to be > existing_record.created_at
        end
      end
    end

    describe '#fixity_check_file' do
      subject(:check_file) { service_by_object.send(:fixity_check_file, f.original_file) }

      specify 'returns a single result' do
        expect(check_file.length).to eq(1)
      end
      describe 'non-versioned file with latest version only' do
        subject(:nv_check_file) { service_by_object.send(:fixity_check_file, f.original_file) }
        let(:service_by_object) { described_class.new(f, async_jobs: false, latest_version_only: true, initiating_user: user.uid) }

        before do
          allow(f.original_file).to receive(:has_versions?).and_return(false)
        end

        specify 'returns a single result' do
          expect(nv_check_file.length).to eq(1)
        end
      end
    end

    describe '#fixity_check_file_version' do
      subject(:check_file_version) { service_by_object.send(:fixity_check_file_version, f.original_file.id, f.original_file.uri.to_s) }

      specify 'returns a single ChecksumAuditLog for the given file' do
        expect(check_file_version).to be_kind_of ChecksumAuditLog
        expect(check_file_version.file_set_id).to eq(f.id)
        expect(check_file_version.checked_uri).to eq(f.original_file.uri)
      end
    end
  end
end
