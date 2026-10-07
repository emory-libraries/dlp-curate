# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::AdminSetCreateService, :clean do
  describe '.find_or_create_default_admin_set' do
    let(:legacy_id) { 'admin_set/default' }
    let(:legacy_admin_set) { instance_double(AdminSetResource, id: legacy_id) }

    before do
      Hyrax::DefaultAdministrativeSet.delete_all if Hyrax::DefaultAdministrativeSet.save_supported?
      Hyrax.config.reset_default_admin_set
    end

    it 'returns an existing legacy default admin set instead of creating a second one' do
      allow(Hyrax.query_service).to receive(:find_by) do |args|
        case args[:id].to_s
        when legacy_id
          legacy_admin_set
        else
          raise Valkyrie::Persistence::ObjectNotFoundError
        end
      end

      result = described_class.find_or_create_default_admin_set
      expect(result).to eq(legacy_admin_set)
    end

    it 'remembers the found default id when the persister table exists' do
      skip 'hyrax_default_administrative_set table is not present' unless Hyrax::DefaultAdministrativeSet.save_supported?

      allow(Hyrax.query_service).to receive(:find_by) do |args|
        case args[:id].to_s
        when legacy_id
          legacy_admin_set
        else
          raise Valkyrie::Persistence::ObjectNotFoundError
        end
      end

      described_class.find_or_create_default_admin_set
      expect(Hyrax::DefaultAdministrativeSet.first.default_admin_set_id).to eq(legacy_id)
    end
  end
end
