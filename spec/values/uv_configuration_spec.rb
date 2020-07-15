# frozen_string_literal: true
require "rails_helper"

describe UvConfiguration do
  subject(:uv_configuration) { described_class.new(foo: "bar") }

  describe ".default_values" do
    it "generates the default configuration options" do
      expect(described_class.default_values["modules"]["footerPanel"]).to include "options"
      expect(described_class.default_values["modules"]["footerPanel"]["options"]).to include(
        "shareEnabled" => false,
        "downloadEnabled" => false
      )
      expect(described_class.default_values["modules"]["moreInfoRightPanel"]["content"]).to include(
        "manifestHeader" => nil
      )
    end
  end

  describe ".new" do
    it "constructs an object with custom properties" do
      expect(uv_configuration).to include "foo"
      expect(uv_configuration["foo"]).to eq "bar"
    end
  end
end
