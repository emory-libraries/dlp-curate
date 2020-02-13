# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ActiveFedora::Fedora do
  subject(:fedora) { described_class.new(config) }
  describe "#authorized_connection" do
    describe "with request options" do
      let(:config) do
        { url:      "https://example.com",
          user:     "fedoraAdmin",
          password: "fedoraAdmin",
          request:  { timeout: 300, open_timeout: 60 } }
      end
      specify do
        expect(Faraday).to receive(:new).with("https://example.com", request: { timeout: 300, open_timeout: 60 }).and_call_original
        fedora.authorized_connection
      end
    end
  end
end
