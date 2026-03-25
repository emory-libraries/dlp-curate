# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Valkyrie::Persistence::Fedora::Persister, :wipe_fedora do
  context "fedora 6 general operations" do
    let(:adapter) do
      Valkyrie::Persistence::Fedora::MetadataAdapter.new(
        **fedora_adapter_config(
          base_path: "test_fed",
          schema: Valkyrie::Persistence::Fedora::PermissiveSchema.new(title: RDF::URI("http://example.com/title")),
          fedora_version: 6
        )
      )
    end
    let(:persister) { adapter.persister }
    let(:query_service) { adapter.query_service }

    it_behaves_like "a Valkyrie::Persister in Curate"
  end
end
