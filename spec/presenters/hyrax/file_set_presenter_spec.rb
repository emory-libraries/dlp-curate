# frozen_string_literal: true
require 'rails_helper'
require 'iiif_manifest'
RSpec.describe Hyrax::FileSetPresenter, :clean do
  let(:file_set) { FactoryBot.create(:file_set) }
  let(:pmf)      { File.open(fixture_path + '/book_page/0003_preservation_master.tif') }
  let(:sf)       { File.open(fixture_path + '/book_page/0003_service.jpg') }
  let(:imf)      { File.open(fixture_path + '/book_page/0003_intermediate.jp2') }
  before do
    Hydra::Works::AddFileToFileSet.call(file_set, pmf, :preservation_master_file)
    Hydra::Works::AddFileToFileSet.call(file_set, sf, :service_file)
    Hydra::Works::AddFileToFileSet.call(file_set, imf, :intermediate_file)
    file_set.to_solr
    file_set.save!
  end
  describe "#display_image" do
    let(:solr_document) { SolrDocument.find(file_set.id) }
    let(:presenter) { described_class.new(solr_document, ManifestAbility.new) }
    context 'displays preferred file' do
      subject { presenter.display_image.url }
      it { is_expected.to include(file_set.service_file.id.split('/').last) }
    end
  end
end
