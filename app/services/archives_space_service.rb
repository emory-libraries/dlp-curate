# frozen_string_literal: true
require "uri"
require "net/http"

class ArchivesSpaceService
  class ClientError < StandardError; end
  class ServerError < StandardError; end

  def initialize
    @config = config = ArchivesSpace::Configuration.new({
                                                          base_uri:   ENV['ARCHIVES_SPACE_API_BASE_URL'].chomp('/'),
                                                          base_repo:  "",
                                                          username:   ENV['ARCHIVES_SPACE_USERNAME'],
                                                          password:   ENV['ARCHIVES_SPACE_PASSWORD'],
                                                          page_size:  50,
                                                          throttle:   0,
                                                          verify_ssl: true,
                                                          timeout:    60
                                                        })
    @client = ArchivesSpace::Client.new(config).login
  end

  def fetch_repositories
    @client.get('/repositories')
  end

  def fetch_repository_by_id(id)
    query = { 'resolve': ['agent_representation'] }
    data = process(response: @client.get("/repositories/#{id}", { query: query }))
    extract_repository(data: data)
  end

  def fetch_resource_by_id(id, repository_id:)
    query = { 'resolve': ['subjects', 'tree', 'linked_agents'] }
    data = process(response: @client.get("/repositories/#{repository_id}/resources/#{id}", { query: query }))
    extract_resource(data: data)
  end

  def fetch_resources_by_call_number(call_number, repository_id:)
    query = { 'identifier[]': [call_number].to_s, 'resolve': ['resources'] }
    @client.get("/repositories/#{repository_id}/find_by_id/resources", { query: query })
  end

  private

    def process(response:)
      if response.status_code == 200
        response.parsed
      elsif 400 <= response.status_code && response.status_code < 500
        raise ArchivesSpaceService::ClientError, response.parsed.to_s
      else
        raise ArchivesSpaceService::ServerError, response.parsed.to_s
      end
    end

    def extract_repository(data:)
      {
        name:                data['name'],
        administrative_unit: data['name'],
        holding_repository:  data['name'],
        institution:         data['parent_institution_name'],
        contact_information: extract_repository_contact(data: data)
      }
    end

    def extract_resource(data:)
      {
        title:                data['title'],
        description:          extract_resource_description(data: data),
        creator:              extract_resource_linked_agents(data: data, type: 'creator'),
        system_of_record_id:  ENV['ARCHIVES_SPACE_PUBLIC_BASE_URL'].chomp('/') + data['uri'],
        call_number:          data['id_0'],
        primary_language:     data['lang_materials']&.first&.dig('language_and_script', 'language'),
        subject_topics:       extract_resource_subjects(data: data, type: 'topical'),
        subject_names:        extract_resource_linked_agents(data: data, type: 'subject'),
        subject_geo:          extract_resource_subjects(data: data, type: 'geographic'),
        subject_time_periods: extract_resource_subjects(data: data, type: 'temporal')
      }
    end

    def extract_repository_contact(data:)
      contact = data.dig('agent_representation', '_resolved', 'agent_contacts')&.first
      return '' if contact.blank?
      address2 = [contact['city'], contact['region'], contact['post_code']].join(', ')
      phone = contact['telephones'].first&.fetch('number', '')
      [contact['name'], data['parent_institution_name'], contact['address_1'], address2, contact['email'], phone].join("\n")
    end

    def extract_resource_description(data:)
      notes = data['notes']&.select { |note| note['type'] == 'abstract' }
      return if notes.blank?
      notes.map { |note| note['content'] }.compact.join("\n")
    end

    def extract_resource_linked_agents(data:, type:)
      agents = data['linked_agents']&.select { |agent| agent['role'] == type }
      return [] if agents.blank?
      agents.map { |agent| agent.dig('_resolved', 'title') }.compact
    end

    def extract_resource_subjects(data:, type:)
      subjects = data['subjects']&.select { |subject| subject.dig('_resolved', 'terms').first&.fetch('term_type') == type }
      return [] if subjects.blank?
      subjects.map { |subject| subject.dig('_resolved', 'title') }.sort
    end
end
