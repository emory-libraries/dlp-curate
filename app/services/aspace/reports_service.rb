# frozen_string_literal: true

module Aspace
  class ReportsService < ApiService
    PAGE_SIZE = 50

    def fetch_repository_last_page(repository_id:)
      query = { 'page': 1, 'page_size': PAGE_SIZE }
      data = process(response: @client.get("/repositories/#{repository_id}/resources", { query: query }))
      data['last_page']
    end

    def fetch_resources_by_page(page, repository_id:)
      query = { 'page': page, 'page_size': PAGE_SIZE }
      data = process(response: @client.get("/repositories/#{repository_id}/resources", { query: query }))
      results = data['results']
      results.map { |result| extract_resource(data: result) }
    end

    private

      def extract_resource(data:)
        {
          ead_id:       data['ead_id'],
          resource_id:  data['uri']&.chomp('/')&.split('/')&.last,
          title:        data['title'],
          call_number:  data['id_0'],
          ead_location: data['ead_location'],
          aspace_url:   ENV['ARCHIVES_SPACE_PUBLIC_BASE_URL'].chomp('/') + data['uri']
        }
      end
  end
end
