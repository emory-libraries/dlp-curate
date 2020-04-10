# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReindexObjectJob, :clean do
  let(:fs1) { FactoryBot.create(:file_set, id: '97634tmpgs-cor', title: ['foo']) }

  it 'reindexes file_sets' do
    timestamp = SolrDocument.find(fs1.id).response['response']['docs'][0]['timestamp']
    described_class.perform_now(fs1.id)
    expect(SolrDocument.find(fs1.id).response['response']['docs'][0]).to include('timestamp')
    expect(SolrDocument.find(fs1.id).response['response']['docs'][0]['timestamp']).to be > timestamp
  end
end
