# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReplaceWorkMembersJob, :clean do
  let(:work) { FactoryBot.create(:work) }
  let(:file_set) { FactoryBot.create(:file_set) }

  before do
    work.ordered_members = [file_set, file_set]
    work.save
  end

  # NOTE: We unfortunately cannot save nil objects into the #ordered_members attribute.
  #   That phenomenon only occurs during Zizia imports using the "shovelling" technique
  #   of adding FileSets to a Work.
  it 'calls the expected methods' do
    expect(FileSet).to receive(:find).with(file_set.id).and_return(file_set)
    expect(work).to receive(:ordered_members=).with([file_set])
    expect(work).to receive(:save)
    described_class.perform_now(work, [file_set.id])
  end
end
