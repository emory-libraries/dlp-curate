# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WorkMembersCleanUpJob, :clean do
  let(:work) { FactoryBot.create(:work) }
  let(:file_set) { FactoryBot.create(:file_set) }

  context 'when called without ids' do
    it 'returns an error' do
      expect { described_class.perform_now }.to(
        raise_error(
          RuntimeError,
           'The required work ids separated by commas were not provided.'
        )
      )
    end
  end

  context 'when called with work with no duplicates or nil objects in #ordered_members' do
    before do
      work.ordered_members = [file_set]
      work.save
    end

    it 'finds work and does not process ReplaceWorkMembersJob' do
      expect(CurateGenericWork).to receive(:find).with(work.id).and_return(work)
      expect(Rails.logger).to receive(:error).with('No nil or duplicate work members were found.')
      expect(ReplaceWorkMembersJob).not_to receive(:perform_later).with(work, [file_set.id])
      described_class.perform_now(work.id)
    end
  end

  # NOTE: We unfortunately cannot save nil objects into the #ordered_members attribute.
  #   That phenomenon only occurs during Zizia imports using the "shovelling" technique
  #   of adding FileSets to a Work.
  context 'when called with a work that contains duplicate objects in #ordered_members' do
    before do
      work.ordered_members = [file_set, file_set]
      work.save
    end

    it 'finds work and processes ReplaceWorkMembersJob' do
      expect(CurateGenericWork).to receive(:find).with(work.id).and_return(work)
      expect(Rails.logger).not_to receive(:error).with('No nil or duplicate work members were found.')
      expect(ReplaceWorkMembersJob).to receive(:perform_later).with(work, [file_set.id])
      described_class.perform_now(work.id)
    end
  end
end
