# frozen_string_literal: true
class ArchivesSpaceController < ApplicationController
  authorize_resource class: :archivesspace

  def initialize
    super
    @service = Aspace::ApiService.new.authenticate
    @formatter = Aspace::FormattingService.new
  end

  # archivesspace/repositories
  def repositories
    repositories = @service.fetch_repositories
    repositories.each { |r| @formatter.format_repository(r) }

    respond_to do |format|
      format.json { render json: repositories.to_json }
    end
  end

  # archivesspace/find_by_id?repository_id=&identifier=
  def find_by_id
    if params['repository_id'].present? && params['identifier'].present?
      data = @service.fetch_resource_by_call_number(params['identifier'], repository_id: params['repository_id'])
      @formatter.format_resource(data)
    else
      data = { error: "Repository and resource identifiers must be specified" }
    end

    respond_to do |format|
      format.json { render json: data.to_json }
    end
  end

  private

    def permitted
      # TODO: Sanitize params
    end
end
