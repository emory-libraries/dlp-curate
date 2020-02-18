# frozen_string_literal: true

require "rails_helper"

RSpec.describe "routes for iiif", type: :routing do
  it "routes iiif image requests to the iiif#show controller" do
    expect(get("/iiif/2/a0f9219f14f071be7e3b872186f3507cfeccd5bf/full/600,/0/default.jpg"))
      .to route_to(
        "controller" => "iiif",
        "action" => "show",
        "identifier" => "a0f9219f14f071be7e3b872186f3507cfeccd5bf",
        "region" => "full",
        "size" => "600,",
        "rotation" => "0",
        "quality" => "default",
        "format" => "jpg"
      )
  end

  it "routes info.json requests to the iiif#info controller" do
    expect(get("/iiif/2/a0f9219f14f071be7e3b872186f3507cfeccd5bf/info.json"))
      .to route_to(
        "controller" => "iiif",
        "action" => "info",
        "identifier" => "a0f9219f14f071be7e3b872186f3507cfeccd5bf"
      )
  end

  it "routes manifest requests to the iiif#manifest controller" do
    expect(get("/iiif/508hdr7srq-cor/manifest"))
      .to route_to(
        "controller" => "iiif",
        "action" => "manifest",
        "identifier" => "508hdr7srq-cor"
      )
  end
end
