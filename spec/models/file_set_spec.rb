require 'rails_helper'

RSpec.describe FileSet do
  it "multiple pcdm_use error" do
    expect { described_class.new(pcdm_use: [described_class::PRIMARY]) }.to raise_error(ArgumentError)
  end
end
