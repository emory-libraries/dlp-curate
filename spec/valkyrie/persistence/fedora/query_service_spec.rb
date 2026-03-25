# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Valkyrie::Persistence::Fedora::QueryService, :wipe_fedora do
  context "fedora 6 general operations" do
    let(:adapter) { Valkyrie::Persistence::Fedora::MetadataAdapter.new(**fedora_adapter_config(base_path: "test_fed", fedora_version: 6)) }
    let(:persister) { adapter.persister }
    let(:query_service) { adapter.query_service }
    it_behaves_like 'a Valkyrie query provider in Curate'
  end
end
