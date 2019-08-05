# frozen_string_literal: true
require 'rails_helper'

describe ParentQueryService do
  let(:parent_doc) { { "response": { "docs": [{ "id": "asdf" }] } }.with_indifferent_access }
  let(:empty_results) { { "response": { "docs": [] } }.with_indifferent_access }
  let(:child_id) { "child_id" }
  describe "#query_parents_for_id" do
    context "when a child work exists with a parent" do
      before do
        allow(ActiveFedora::SolrService).to receive(:get).with("member_ids_ssim:#{child_id}", rows: 1000).and_return(parent_doc)
      end
      it "returns the parent works" do
        expect(described_class.query_parents_for_id(child_id).length).to eq 1
      end
    end
    context "when a work exists without a parent" do
      before do
        allow(ActiveFedora::SolrService).to receive(:get).with("member_ids_ssim:#{child_id}", rows: 1000).and_return(empty_results)
      end
      it "returns an empty array" do
        expect(described_class.query_parents_for_id(child_id).length).to eq 0
      end
    end
  end
end
