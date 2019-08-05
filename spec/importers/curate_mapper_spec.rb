# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurateMapper do
  subject(:mapper) { described_class.new }

  let(:metadata) do
    {
      "Desc - Title" => "what an awesome title" # title
    }
  end

  before { mapper.metadata = metadata }

  it 'is configured to be the zizia metadata mapper' do
    expect(Zizia.config.metadata_mapper_class).to eq described_class
  end

  it "maps resource type to local authority values, if possible" do
    expect(mapper.title).to contain_exactly(
      "what an awesome title"
    )
  end

  it "maps the required title field" do
    expect(mapper.map_field(:title))
      .to contain_exactly("what an awesome title")
  end

  describe '#fields' do
    it 'has expected fields' do
      expect(mapper.fields).to include(
        :title,
        :visibility
      )
    end
  end
end
