# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AssociateFilesetsWithWorkJob, :clean, perform_enqueued: [AssociateFilesetsWithWorkJob] do
  let(:user) { FactoryBot.create(:user) }
  let(:importer) do
    Bulkrax::Importer.create(
      name:         "Test Importer",
      admin_set_id: "admin_set/default",
      parser_klass: "Bulkrax::CsvParser",
      user_id:      user.id
    )
  end
  let(:generic_work) { FactoryBot.create(:public_generic_work, deduplication_key: "Blah") }
  let(:parent) { generic_work.id }
  let(:entry) do
    Bulkrax::CsvFileSetEntry.create(
      importerexporter_id: importer.id,
      parsed_metadata:     { 'parent' => [parent] }
    )
  end
  let(:file_set) { FactoryBot.create(:file_set, user: user) }
  let(:file_set_entries) { described_class.new.send(:pull_file_set_entries, importer) }
  let(:parents) { described_class.new.send(:pull_parents, file_set_entries) }
  let(:fake_factory) { double }
  let(:fake_job) { instance_double(described_class) }

  before do
    entry.reload
    importer.reload
    described_class.any_instance.stub(:pull_fileset_entries_for_parent).with(any_args).and_return([entry])
    allow(entry).to receive(:factory).and_return(fake_factory)
    allow(fake_factory).to receive(:find).and_return(file_set)
  end

  it '#perform_now associates the file_set with the work' do
    expect(Hyrax.config.callback).to receive(:run)
    check_for_file_set_association(described_class.perform_now(importer))
  end

  context '#pull_file_set_entries' do
    it('pulls the one entry') { expect(file_set_entries).to match_array [entry] }
  end

  context('#pull_parents') { it('pulls the one parent') { expect(parents).to match_array [parent] } }

  context '#pull_work' do
    it "pulls the Work when the query value is the Work's id" do
      expect(described_class.new.send(:pull_work, parent)).to eq(generic_work)
    end

    context 'deduplication_key' do
      it('pulls the Work') do
        expect(described_class.new.send(:pull_work, 'Blah')).to eq(generic_work)
      end
    end
  end

  context '#pull_fileset_entries_for_parent' do
    it 'pulls the entry' do
      expect(
        described_class.new.send(:pull_fileset_entries_for_parent, file_set_entries, parent)
      ).to match_array [entry]
    end
  end

  context '#pull_file_sets' do
    it 'pulls the file_set' do
      expect(described_class.new.send(:pull_file_sets, file_set_entries, parent)).to match_array [file_set]
    end
  end

  context '#process_file_sets' do
    it 'associates the file_set with the work' do
      expect(Hyrax.config.callback).to receive(:run)
      check_for_file_set_association(
        described_class.new.send(:process_file_sets, parents, file_set_entries)
      )
    end
  end

  def check_for_file_set_association(command)
    command && expect(generic_work.reload.ordered_member_ids).to(match_array([file_set.id]))
  end
end
