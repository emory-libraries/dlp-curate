# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Curate::CollectionSharingService do
  let(:collection_id) { 'peel-collection' }
  let(:collection) { CollectionResource.new(id: Valkyrie::ID.new(collection_id)) }
  let(:shares_with_new_works) { true }
  let(:template) { instance_double(Hyrax::PermissionTemplate) }
  let(:grants) { { %w[group manage] => ['rose_manager'], %w[group view] => ['rose_viewer'], %w[user manage] => [], %w[user view] => [] } }

  # Stands in for a Valkyrie resource's permission manager accessors, which treat agents as a set.
  let(:resource_class) do
    Struct.new(:id, :member_of_collection_ids, :edit_groups, :edit_users, :read_groups, :read_users, :acl, keyword_init: true) do
      [:edit_groups, :edit_users, :read_groups, :read_users].each do |agents|
        define_method(:"#{agents}=") { |value| self[agents] = value.uniq }
      end
      def permission_manager = Struct.new(:acl).new(acl)
      def work? = true
    end
  end
  let(:work) { resource_class.new(id: 'work-1', member_of_collection_ids: [collection_id], acl: work_acl, **owner_grants) }
  let(:file_set) { resource_class.new(id: 'fs-1', acl: file_set_acl, **owner_grants) }
  let(:owner_grants) { { edit_groups: ['admin'], edit_users: ['depositor'], read_groups: [], read_users: [] } }
  let(:work_acl) { double('work acl', save: true) }
  let(:file_set_acl) { double('file set acl', save: true) }

  before do
    allow(Hyrax.query_service).to receive(:find_by).with(id: collection_id).and_return(collection)
    allow(Hyrax::CollectionType).to receive(:for).with(collection:)
                                                 .and_return(instance_double(Hyrax::CollectionType, share_applies_to_new_works?: shares_with_new_works))
    allow(Hyrax::PermissionTemplate).to receive(:find_by).with(source_id: collection_id).and_return(template)
    allow(template).to receive(:agent_ids_for) { |agent_type:, access:| grants[[agent_type, access]] }
    allow(Hyrax).to receive(:custom_queries).and_return(double('custom queries', find_child_file_sets: [file_set]))
    allow(Hyrax.index_adapter).to receive(:save)
  end

  describe '.template_for' do
    it "returns the template of the work's only collection when its type shares with new works" do
      expect(described_class.template_for(work)).to eq template
    end

    context 'when the collection type does not share with new works' do
      let(:shares_with_new_works) { false }

      it { expect(described_class.template_for(work)).to be_nil }
    end

    it 'returns nil for a work in several collections, as the AF actor does' do
      work.member_of_collection_ids = [collection_id, 'other-collection']

      expect(described_class.template_for(work)).to be_nil
    end

    it 'returns nil for a work in no collection' do
      work.member_of_collection_ids = []

      expect(described_class.template_for(work)).to be_nil
    end

    it 'returns nil when the collection cannot be found' do
      allow(Hyrax.query_service).to receive(:find_by).with(id: collection_id).and_raise(Valkyrie::Persistence::ObjectNotFoundError)

      expect(described_class.template_for(work)).to be_nil
    end
  end

  describe '.apply' do
    it "gives the collection's managers edit and its viewers read access, without saving" do
      expect(described_class.apply(work)).to be true
      expect(work.edit_groups).to contain_exactly('admin', 'rose_manager')
      expect(work.read_groups).to contain_exactly('rose_viewer')
      expect(work_acl).not_to have_received(:save)
    end

    context 'when no collection sharing applies' do
      let(:shares_with_new_works) { false }

      it 'leaves the work alone' do
        expect(described_class.apply(work)).to be false
        expect(work.edit_groups).to eq ['admin']
      end
    end
  end

  describe '.share_with_saved' do
    it 'saves and reindexes the work and its FileSets with the added grants' do
      expect(described_class.share_with_saved(work)).to eq [work, file_set]
      expect(file_set.read_groups).to contain_exactly('rose_viewer')
      expect(work_acl).to have_received(:save)
      expect(file_set_acl).to have_received(:save)
      expect(Hyrax.index_adapter).to have_received(:save).with(resource: work)
      expect(Hyrax.index_adapter).to have_received(:save).with(resource: file_set)
    end

    it 'only reports what would change on a dry run' do
      expect(described_class.share_with_saved(work, dry_run: true)).to eq [work, file_set]
      expect(work_acl).not_to have_received(:save)
      expect(Hyrax.index_adapter).not_to have_received(:save)
    end

    it 'saves nothing when the grants are already there' do
      work.edit_groups += ['rose_manager']
      work.read_groups += ['rose_viewer']

      expect(described_class.share_with_saved(work)).to eq [file_set]
      expect(work_acl).not_to have_received(:save)
    end

    context 'with an AF work' do
      let(:af_work) { CurateGenericWork.new(id: 'af-work', edit_groups: ['admin']) }

      before do
        allow(af_work).to receive_messages(member_of_collection_ids: [collection_id], file_sets: [], save!: true)
      end

      it 'saves it through ActiveFedora' do
        expect(described_class.share_with_saved(af_work)).to eq [af_work]
        expect(af_work.edit_groups).to contain_exactly('admin', 'rose_manager')
        expect(af_work).to have_received(:save!)
      end
    end
  end
end
