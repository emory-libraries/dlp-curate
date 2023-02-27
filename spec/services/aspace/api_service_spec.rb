# frozen_string_literal: true

require 'rails_helper'

describe Aspace::ApiService do
  # rubocop:disable Layout/LineLength
  let(:client) { ArchivesSpace::Client.new }
  let(:repository_data) { JSON.parse(File.open(Rails.root.join("spec", "fixtures", "archivesspace_api", "repository.json")).read) }
  let(:resource_data) { JSON.parse(File.open(Rails.root.join("spec", "fixtures", "archivesspace_api", "resource.json")).read) }

  before do
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_API_BASE_URL').and_return('aspace_api_base_url')
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_PUBLIC_BASE_URL').and_return('aspace_public_base_url')
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_USERNAME').and_return('username')
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_PASSWORD').and_return('password')
  end

  describe '#fetch_repositories' do
    let(:repositories_data) { JSON.parse(File.open(Rails.root.join("spec", "fixtures", "archivesspace_api", "repositories.json")).read) }
    let(:response) { instance_double("ArchivesSpace::Response", status_code: 200, parsed: repositories_data) }

    before do
      allow(ArchivesSpace::Client).to receive(:new).and_return(client)
      allow(client).to receive(:login).and_return(true)
      allow(client).to receive(:get).with('/repositories').and_return(response)
    end

    it 'requests all repositories from ArchivesSpace API' do
      expect(client).to receive(:get).with('/repositories')
      service = described_class.new.authenticate!
      service.fetch_repositories
    end

    it 'formats data for repositories fetched' do
      service = described_class.new
      expect(service).to receive(:extract_repository).with(data: repositories_data.first)
      service.fetch_repositories
    end
  end

  describe '#fetch_repository_by_id' do
    let(:response) { instance_double("ArchivesSpace::Response", status_code: 200, parsed: repository_data) }

    before do
      allow(ArchivesSpace::Client).to receive(:new).and_return(client)
      allow(client).to receive(:login).and_return(true)
      allow(client).to receive(:get).with('/repositories/7', { query: { resolve: ["agent_representation"] } }).and_return(response)
    end

    it 'requests repository from ArchivesSpace API' do
      expect(client).to receive(:get).with('/repositories/7', { query: { resolve: ["agent_representation"] } })
      service = described_class.new.authenticate!
      service.fetch_repository_by_id('7')
    end

    it 'formats data for the repository fetched' do
      service = described_class.new
      expect(service).to receive(:extract_repository).with(data: repository_data)
      service.fetch_repository_by_id('7')
    end
  end

  describe '#fetch_resource_by_ref' do
    let(:response) { instance_double("ArchivesSpace::Response", status_code: 200, parsed: resource_data) }

    before do
      allow(ArchivesSpace::Client).to receive(:new).and_return(client)
      allow(client).to receive(:login).and_return(true)
      allow(client).to receive(:get).with('/repositories/7/resources/5687', { query: { resolve: ["subjects", "linked_agents"] } }).and_return(response)
    end

    it 'requests resource from ArchivesSpace API' do
      expect(client).to receive(:get).with('/repositories/7/resources/5687', { query: { resolve: ["subjects", "linked_agents"] } })
      service = described_class.new.authenticate!
      service.fetch_resource_by_ref('/repositories/7/resources/5687')
    end

    it 'formats data for the resource fetched' do
      service = described_class.new
      expect(service).to receive(:extract_resource).with(data: resource_data)
      service.fetch_resource_by_ref('/repositories/7/resources/5687')
    end
  end

  describe '#fetch_resource_by_call_number' do
    let(:call_number) { 'Manuscript Collection No. 892' }
    let(:resource_response) { instance_double("ArchivesSpace::Response", status_code: 200, parsed: resource_data) }
    let(:find_by_id_data) { JSON.parse(File.open(Rails.root.join("spec", "fixtures", "archivesspace_api", "find_by_id_resources.json")).read) }
    let(:find_by_id_response) { instance_double("ArchivesSpace::Response", status_code: 200, parsed: find_by_id_data) }

    before do
      allow(ArchivesSpace::Client).to receive(:new).and_return(client)
      allow(client).to receive(:login).and_return(true)
      allow(client).to receive(:get).with('/repositories/7/find_by_id/resources', { query: { 'identifier[]': [call_number].to_s, 'resolve': ['resources'] } }).and_return(find_by_id_response)
      allow(client).to receive(:get).with('/repositories/7/resources/5687', { query: { resolve: ["subjects", "linked_agents"] } }).and_return(resource_response)
    end

    it 'searches ArchivesSpace API for the resource' do
      expect(client).to receive(:get).with('/repositories/7/find_by_id/resources', { query: { 'identifier[]': [call_number].to_s, 'resolve': ['resources'] } })
      service = described_class.new.authenticate!
      service.fetch_resource_by_call_number(call_number, repository_id: '7')
    end

    context 'when one resource is found' do
      it 'fetches data for the resource found' do
        service = described_class.new
        expect(service).to receive(:fetch_resource_by_ref).with('/repositories/7/resources/5687')
        service.fetch_resource_by_call_number(call_number, repository_id: '7')
      end
    end

    context 'when more than one resource is found' do
      let(:find_by_id_data) { JSON.parse(File.open(Rails.root.join("spec", "fixtures", "archivesspace_api", "duplicate_find_by_id_resources.json")).read) }

      it 'raises error' do
        service = described_class.new
        expect { service.fetch_resource_by_call_number(call_number, repository_id: '7') }.to raise_error(Aspace::ApiService::ClientError, 'Two or more resources have the same call number Manuscript Collection No. 892')
      end
    end

    context 'when no resources were found' do
      let(:find_by_id_data) { JSON.parse("{\"resources\": []}") }

      it 'raises error' do
        service = described_class.new
        expect { service.fetch_resource_by_call_number(call_number, repository_id: '7') }.to raise_error(Aspace::ApiService::ClientError, 'No resources match call number Manuscript Collection No. 892')
      end
    end
  end

  describe '#extract_repository' do
    it 'formats data correctly' do
      service = described_class.new
      repository = service.extract_repository(data: repository_data)
      expect(repository[:repository_id]).to eq "7"
      expect(repository[:name]).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      expect(repository[:administrative_unit]).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      expect(repository[:holding_repository]).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      expect(repository[:institution]).to eq "Emory University"
      expect(repository[:contact_information]).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library\nEmory University Libraries\n540 Asbury Circle\nAtlanta, Georgia, 30322\nrose.library@emory.edu\n404-727-6887"
    end
  end

  describe '#extract_resource' do
    it 'formats data correctly' do
      service = described_class.new
      resource = service.extract_resource(data: resource_data)
      print(resource)
      expect(resource[:resource_id]).to eq "5687"
      expect(resource[:title]).to eq "William Levi Dawson papers"
      expect(resource[:description]).to eq "Papers of William Levi Dawson, African American composer, conductor, and educator from Anniston, Alabama, including correspondence, original scores of Dawson's works, personal and family papers, photographs, audio visual materials, and printed material."
      expect(resource[:creator]).to eq ["Dawson, William Levi, 1899-1990."]
      expect(resource[:system_of_record_id]).to eq "aspace_public_base_url/repositories/7/resources/5687"
      expect(resource[:call_number]).to eq "Manuscript Collection No. 892"
      expect(resource[:primary_language]).to eq "eng"
      expect(resource[:subject_topics]).to eq ["African American choral conductors.", "African American composers.", "African American conductors.", "African American musicians.", "African American students.", "African American universities and colleges--Alabama.", "African American women.", "African Americans--Education (Higher)--Alabama.", "African Americans--Music.", "Copyright--United States.", "Music publishing.", "Spirituals (Songs)"]
      expect(resource[:subject_names]).to eq ["Dawson, William Levi, 1899-1990.", "Ellison, Ralph.", "Krasilovsky, M. William.", "Spady, James G.", "Stokowski, Leopold, 1882-1977.", "Fisk University.", "Tuskegee Institute.", "Tuskegee Institute. Choir.", "Tuskegee Normal and Industrial Institute.", "Tuskegee University."]
      expect(resource[:subject_geo]).to eq ["Africa--Description and travel."]
      expect(resource[:subject_time_periods]).to eq ["Test Subject Temporal."]
    end
  end
  # rubocop:enable Layout/LineLength
end
