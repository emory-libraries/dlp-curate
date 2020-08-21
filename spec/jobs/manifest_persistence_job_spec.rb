# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestPersistenceJob, :clean do
  let(:work) { FactoryBot.create(:public_generic_work) }
  let(:file_set)  { FactoryBot.create(:file_set, read_groups: ['public']) }
  let(:file_set2) { FactoryBot.create(:file_set, read_groups: ['public']) }
  let(:file_set3) { FactoryBot.create(:file_set, id: '608hdr7srt-cor', read_groups: ['public']) }
  let(:pmf) { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:sf) { File.open(fixture_path + '/book_page/0003_service.jpg') }
  let(:pdf) { File.open(fixture_path + '/sample-file.pdf') }

  before do
    Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(file_set, sf, :service_file)
    Hydra::Works::AddFileToFileSet.call(file_set2, pmf, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(file_set3, pdf, :preservation_master_file)
    work.ordered_members << file_set
    work.ordered_members << file_set2
    work.ordered_members << file_set3
    work.save!
  end

  after do
    work.ordered_members = []
    work.save!
  end

  context "#image_concerns instance method" do
    let(:child_work) { FactoryBot.create(:public_generic_work) }
    before do
      work.ordered_members << child_work
      work.save!
    end

    it "returns file_set_ids" do
      expect(described_class.new.send(:image_concerns, work)).to match_array [file_set.id, file_set2.id, file_set3.id]
    end
  end
end
