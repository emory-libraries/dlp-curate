# frozen_string_literal: true
require "rails_helper"

RSpec.describe "UV Configuration Routes", type: :routing do
  it "routes requests for uv configurations with a resource ID" do
    expect(get("/uv/config/resource-id")).to route_to(
      format:     :json,
      controller: "application",
      action:     "uv_config",
      id:         "resource-id"
    )
  end
end
