# frozen_string_literal: true

require "rails_helper"

RSpec.describe "routes for full-text indexing", type: :routing do
  it "routes full-text indexing requests to the full_text_indexing#full_text_index controller" do
    expect(post("/concern/curate_generic_works/1/full_text_index?user_id=1"))
      .to route_to(
        "controller" => "full_text_indexing",
        "action" => "full_text_index",
        "work_id" => "1",
        "user_id" => "1"
      )
  end

  it "routes full-text indexing with pages requests to the full_text_indexing#full_text_index_with_pages" do
    expect(post("/concern/curate_generic_works/1/full_text_index_with_pages?user_id=1"))
      .to route_to(
        "controller" => "full_text_indexing",
        "action" => "full_text_index_with_pages",
        "work_id" => "1",
        "user_id" => "1"
      )
  end
end
