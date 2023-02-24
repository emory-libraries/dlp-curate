# frozen_string_literal: true
class AspaceController < ApplicationController
  class InvalidRequestError < StandardError; end

  API = Aspace::ApiService

  authorize_resource class: :archivesspace
  before_action :verify_json_request
  before_action :authenticate

  # aspace/repositories
  def repositories
    begin
      data = service.fetch_repositories
      data.each { |r| formatter.format_repository(r) }
    rescue API::ClientError, API::ServerError => e
      data = { error: "ArchivesSpace API error: #{e.message}" }
    end

    render json: data.to_json
  end

  # aspace/find_by_id?repository_id=&call_number=
  def find_by_id
    begin
      verify_presence!(['call_number', 'repository_id'])

      resource = service.fetch_resource_by_call_number(params['call_number'], repository_id: params['repository_id'])
      formatter.format_resource(resource)

      repository = service.fetch_repository_by_id(params['repository_id'])
      formatter.format_repository(repository)

      data = { repository: repository, resource: resource }
    rescue InvalidRequestError => e
      data = { error: "Invalid request error: #{e.message}" }
    rescue API::ClientError, API::ServerError => e
      data = { error: "ArchivesSpace API error: #{e.message}" }
    end

    render json: data.to_json
  end

  private

    def service
      @service ||= Aspace::ApiService.new
    end

    def formatter
      @formatter ||= Aspace::FormattingService.new
    end

    def verify_presence!(required_params)
      required_params.each do |param|
        params[param].presence || raise(InvalidRequestError, "#{param} must be specified")
      end
    end

    def verify_json_request
      render body: nil, status: :bad_request if request.format != :json
    end

    def authenticate
      service.authenticate!
    rescue API::AuthenticationError => e
      data = { error: "ArchivesSpace API error: #{e.message}" }
      render json: data.to_json
    end
end
