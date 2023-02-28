# frozen_string_literal: true

require 'rails_helper'

describe Aspace::ReportsService do
  let(:client) { ArchivesSpace::Client.new }
  let(:repository_id) { '7' }
  let(:resource_data) { JSON.parse(File.open(Rails.root.join("spec", "fixtures", "archivesspace_api", "resources_by_page.json")).read) }
  let(:response) { instance_double("ArchivesSpace::Response", status_code: 200, parsed: resource_data) }
  let(:service) { described_class.new }

  before do
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_API_BASE_URL').and_return('aspace_api_base_url')
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_PUBLIC_BASE_URL').and_return('aspace_public_base_url')
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_USERNAME').and_return('username')
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_PASSWORD').and_return('password')
    allow(ArchivesSpace::Client).to receive(:new).and_return(client)
  end

  describe '#fetch_repository_last_page' do
    let(:response) { instance_double("ArchivesSpace::Response", status_code: 200, parsed: resource_data) }

    before do
      allow(client).to receive(:get).with('/repositories/7/resources', { query: { page: 1, page_size: 50 } }).and_return(response)
    end

    it 'fetches first page of the repository' do
      expect(client).to receive(:get).with('/repositories/7/resources', { query: { page: 1, page_size: 50 } })
      service.fetch_repository_last_page(repository_id: repository_id)
    end

    it 'returns last page number in the repository' do
      last_page = service.fetch_repository_last_page(repository_id: repository_id)
      expect(last_page).to eq 1323
    end
  end

  describe '#fetch_resources_by_page' do
    let(:response) { instance_double("ArchivesSpace::Response", status_code: 200, parsed: resource_data) }

    before do
      allow(client).to receive(:get).with('/repositories/7/resources', { query: { page: 2, page_size: 50 } }).and_return(response)
    end

    it 'fetches requested page of the repository' do
      expect(client).to receive(:get).with('/repositories/7/resources', { query: { page: 2, page_size: 50 } })
      service.fetch_resources_by_page(2, repository_id: repository_id)
    end

    it 'returns data in valid format' do
      data = service.fetch_resources_by_page(2, repository_id: repository_id)
      valid_format = [
        {
          resource_id:  "1",
          title:        "test_collection_title",
          call_number:  "test_call_number",
          ead_id:       "test_ead_id",
          ead_location: "test_ead_location",
          aspace_url:   "aspace_public_base_url/repositories/1/resources/1"
        }
      ]
      expect(data).to eq valid_format
    end
  end
end
