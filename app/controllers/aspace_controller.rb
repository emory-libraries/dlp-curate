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
      response = data.map { |r| formatter.format_repository(r) }
    rescue API::ClientError, API::ServerError => e
      response = { error: "ArchivesSpace API error: #{e.message}" }
    end

    render json: response.to_json
  end

  # aspace/find_by_id?repository_id=&call_number=
  def find_by_id
    begin
      verify_presence!(['call_number', 'repository_id'])

      data = service.fetch_resource_by_call_number(params['call_number'], repository_id: params['repository_id'])
      resource = formatter.format_resource(data)

      data = service.fetch_repository_by_id(params['repository_id'])
      repository = formatter.format_repository(data)

      response = { repository: repository, resource: resource }
    rescue InvalidRequestError => e
      response = { error: "Invalid request error: #{e.message}" }
    rescue API::ClientError, API::ServerError => e
      response = { error: "ArchivesSpace API error: #{e.message}" }
    end

    render json: response.to_json
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
      response = { error: "ArchivesSpace API error: #{e.message}" }
      render json: response.to_json
    end
end
