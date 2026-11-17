# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib', 'frigg', 'persister')

RSpec.describe Frigg::Persister do
  subject(:persister) { described_class.new(adapter:) }
  let(:adapter) { double('Frigg::MetadataAdapter', resource_factory:) }
  let(:resource_factory) { double('ResourceFactory', to_resource: migrated) }
  let(:orm_object) { double('orm') }
  let(:migrated) { CollectionResource.new(id: 'coll-1') }
  let(:legacy_permissions) do
    [Hyrax::Permission.new(access_to: 'coll-1', agent: 'group/public', mode: :read),
     Hyrax::Permission.new(access_to: 'coll-1', agent: 'group/admin', mode: :edit)]
  end
  let(:existing_acl) { instance_double(Hyrax::AccessControl, persisted?: acl_persisted) }
  let(:acl_persisted) { false }

  before do
    allow(Hyrax.config).to receive(:valkyrie_transition?).and_return(true)
    allow(Hyrax::AccessControl).to receive(:for).with(resource: migrated).and_return(existing_acl)
    allow(persister).to receive(:save)
  end

  describe '#convert_and_migrate_resource' do
    it 'saves the legacy permissions as an ACL for the migrated resource' do
      expect(persister.convert_and_migrate_resource(orm_object, true, legacy_permissions)).to eq migrated

      expect(persister).to have_received(:save) do |resource:|
        expect(resource).to be_a Hyrax::AccessControl
        expect(resource.access_to).to eq migrated.id
        expect(resource.permissions.map { |p| [p.access_to, p.agent, p.mode] })
          .to contain_exactly([migrated.id, 'group/public', :read], [migrated.id, 'group/admin', :edit])
      end
    end

    context 'when the migrated resource already has an ACL' do
      let(:acl_persisted) { true }

      it 'leaves it alone' do
        persister.convert_and_migrate_resource(orm_object, true, legacy_permissions)

        expect(persister).not_to have_received(:save)
      end
    end

    it 'does nothing for resources that were not AF-backed' do
      persister.convert_and_migrate_resource(orm_object, false, legacy_permissions)

      expect(persister).not_to have_received(:save)
    end

    it 'does nothing without legacy permissions' do
      persister.convert_and_migrate_resource(orm_object, true, nil)

      expect(persister).not_to have_received(:save)
    end
  end

  describe '#migrate_preservation_workflows' do
    let(:work) { CurateGenericWorkResource.new(id: 'work-1') }
    let(:legacy_workflows) { [PreservationWorkflowResource.new(workflow_type: 'Ingest')] }

    before { allow(persister).to receive(:save) { |resource:| resource } }

    it 'copies the AF workflows onto the migrated work' do
      migrated = persister.send(:migrate_preservation_workflows, work, legacy_workflows)

      expect(migrated.preservation_workflow.map(&:workflow_type)).to eq ['Ingest']
      expect(persister).to have_received(:save).with(resource: work)
    end

    it 'leaves a work that already has workflows alone' do
      work.preservation_workflow = [PreservationWorkflowResource.new(workflow_type: 'Accession')]

      expect(persister.send(:migrate_preservation_workflows, work, legacy_workflows)).to eq work
      expect(persister).not_to have_received(:save)
    end

    it 'does nothing for resources without workflows' do
      collection = CollectionResource.new(id: 'coll-1')

      expect(persister.send(:migrate_preservation_workflows, collection, legacy_workflows)).to eq collection
      expect(persister).not_to have_received(:save)
    end
  end

  describe '#legacy_preservation_workflows' do
    let(:legacy) { CurateGenericWorkResource.new(id: 'work-1') }
    let(:af_work) { CurateGenericWork.new.tap { |w| w.preservation_workflow_attributes = [{ workflow_type: 'Ingest', workflow_notes: 'note' }] } }

    it 'reads the AF workflows as Valkyrie workflows' do
      allow(ActiveFedora::Base).to receive(:find).with('work-1').and_return(af_work)

      workflows = persister.send(:legacy_preservation_workflows, legacy)

      expect(workflows.map { |w| [w.workflow_type, w.workflow_notes] }).to eq [['Ingest', 'note']]
    end

    it 'returns nil when the AF work cannot be read' do
      allow(ActiveFedora::Base).to receive(:find).with('work-1').and_raise(StandardError, 'Fedora unavailable')

      expect(persister.send(:legacy_preservation_workflows, legacy)).to be_nil
    end
  end

  describe '#legacy_access_permissions' do
    let(:legacy) { CollectionResource.new(id: 'coll-1') }

    it 'reads the permissions through the ACL lookup' do
      allow(Hyrax::AccessControl).to receive(:for).with(resource: legacy)
                                                  .and_return(instance_double(Hyrax::AccessControl, permissions: legacy_permissions))

      expect(persister.send(:legacy_access_permissions, legacy)).to eq legacy_permissions
    end

    it 'returns nil when the lookup fails' do
      allow(Hyrax::AccessControl).to receive(:for).with(resource: legacy).and_raise(StandardError, 'Fedora unavailable')

      expect(persister.send(:legacy_access_permissions, legacy)).to be_nil
    end
  end
end
