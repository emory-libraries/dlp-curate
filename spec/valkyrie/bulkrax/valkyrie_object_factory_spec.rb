# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Bulkrax::ValkyrieObjectFactory do
  describe '#update_work' do
    subject(:factory) { described_class.allocate }
    let(:work) { CurateGenericWorkResource.new(id: Valkyrie::ID.new('work-1')) }
    let(:transaction) { double('update_work transaction') }
    let(:user) { instance_double(User, email: 'importer@emory.edu') }

    before do
      factory.instance_variable_set(:@user, user)
      allow(factory).to receive_messages(object: work, prep_fileset_content: [[], []])
      allow(factory).to receive(:perform_transaction_for) { |**, &block| block.call && work }
      allow(described_class).to receive(:transactions).and_return('change_set.update_work' => transaction)
      allow(transaction).to receive(:with_step_args).and_return(transaction)
      allow(factory).to receive(:create_preservation_event)
    end

    it 'passes the importing user to the Modification preservation event step' do
      expect(factory.send(:update_work, {})).to eq work
      expect(transaction).to have_received(:with_step_args)
        .with(hash_including('change_set.add_work_modification_event' => { initiating_user: 'importer@emory.edu' }))
    end

    it 'no longer adds the event with a separate save after the update' do
      factory.send(:update_work, {})

      expect(factory).not_to have_received(:create_preservation_event)
    end
  end
end
