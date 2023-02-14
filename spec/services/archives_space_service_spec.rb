# frozen_string_literal: true

require 'rails_helper'

describe ArchivesSpaceService do
  # rubocop:disable Layout/LineLength
  let(:repository_data) { JSON.parse(File.open(Rails.root.join("spec", "fixtures", "archivesspace", "repository.json")).read) }
  let(:resource_data) { JSON.parse(File.open(Rails.root.join("spec", "fixtures", "archivesspace", "resource.json")).read) }

  before do
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_API_BASE_URL').and_return('aspace_api_base_url')
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_PUBLIC_BASE_URL').and_return('aspace_public_base_url')
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_USERNAME').and_return('username')
    allow(ENV).to receive(:[]).with('ARCHIVES_SPACE_PASSWORD').and_return('password')
  end

  describe '#extract_repository' do
    it 'formats data correctly' do
      service = described_class.new
      repository = service.extract_repository(data: repository_data)
      expect(repository[:name]).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      expect(repository[:administrative_unit]).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      expect(repository[:holding_repository]).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library"
      expect(repository[:institution]).to eq "Emory University Libraries"
      expect(repository[:contact_information]).to eq "Stuart A. Rose Manuscript, Archives, and Rare Book Library\nEmory University Libraries\n540 Asbury Circle\nAtlanta, Georgia, 30322\nrose.library@emory.edu\n404-727-6887"
    end
  end

  describe '#extract_resource' do
    it 'formats data correctly' do
      service = described_class.new
      resource = service.extract_resource(data: resource_data)
      print(resource)
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
