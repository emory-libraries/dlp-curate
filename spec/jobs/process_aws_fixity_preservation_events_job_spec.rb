# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ProcessAwsFixityPreservationEventsJob, :clean do
  let(:user) { FactoryBot.create(:user) }
  let(:file_set) { FactoryBot.create(:file_set) }
  let(:csv) { fixture_path + '/csv_import/aws_fixity_test.csv' }
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }

  before do
    Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
    allow(FileSet).to receive(:where)
      .with(sha1_tesim: 'f43b4b662480a4477100bf3de73804f8efbcba30')
      .and_return([file_set])
  end

  describe "called with perform_now" do
    it 'changes the number of preversation_events on the file_set' do
      expect { described_class.perform_now(csv) }
        .to change { file_set.preservation_event.size }.from(1).to(2)
    end

    it 'adds the expected preservation event' do
      described_class.perform_now(csv)

      expect(file_set.preservation_event.pluck(:event_details))
        .to include(["Fixity intact for sha1: f43b4b662480a4477100bf3de73804f8efbcba30 in fedora-cor-arch-binaries"])
      expect(file_set.preservation_event.pluck(:event_type)).to include(["Fixity Check"])
      expect(file_set.preservation_event.pluck(:initiating_user)).to include(["AWS Serverless Fixity"])
      expect(file_set.preservation_event.pluck(:outcome)).to include(["Success"])
      expect(file_set.preservation_event.pluck(:software_version))
        .to include(["Serverless Fixity v1.0"])
      expect(file_set.preservation_event.pluck(:event_start)).to include(["2022-03-09 14:11:25"])
      expect(file_set.preservation_event.pluck(:event_end)).to include(["2022-03-09 14:11:35"])
    end
  end
end
