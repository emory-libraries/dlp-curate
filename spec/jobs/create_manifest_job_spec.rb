# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CreateManifestJob, :clean do
  let(:generic_work)  { FactoryBot.create(:public_work, id: '888888', title: ['foo']) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:request) { ENV['HOSTNAME'] = 'example.org' }
  let(:ability) { instance_double(Ability) }
  let(:user_key) { 'a_user_key' }
  let(:attributes) do
    { "id" => '888888',
      "title_tesim" => ['foo'],
      "human_readable_type_tesim" => ["Curate Generic Work"],
      "has_model_ssim" => ["CurateGenericWork"],
      "date_created_tesim" => ['an unformatted date'],
      "date_modified_dtsi" => "2019-11-11T18:20:32Z",
      "depositor_tesim" => user_key,
      "manifest_cache_key_tesim" => ["d28c5b20cf9b9663181d02b5ce90fac59fa666d7"] }
  end
  let(:presenter) { described_class.new(solr_document, ability, request) }

  before do
    ENV['IIIF_MANIFEST_CACHE'] = "./tmp"
    allow(CurateGenericWork).to receive(:all).and_return([generic_work])
    allow(CurateGenericWork).to receive(:find).and_return(generic_work)
    allow(SolrDocument).to receive(:find).and_return(solr_document)
    FileUtils.rm_f("./tmp/d28c5b20cf9b9663181d02b5ce90fac59fa666d7_888888")
  end

  it 'creates manifest and saves to tmp', perform_enqueued: [ManifestPersistenceJob] do
    expect(File).not_to exist("./tmp/d28c5b20cf9b9663181d02b5ce90fac59fa666d7_888888")
    described_class.perform_now
    expect(File).to exist("./tmp/d28c5b20cf9b9663181d02b5ce90fac59fa666d7_888888")
  end
end
