# frozen_string_literal: true

class IiifController < ApplicationController
  def show
    @iiif_url = iiif_url
    Rails.logger.info("Trying to proxy image from #{@iiif_url}")
    response.set_header('Access-Control-Allow-Origin', '*')
    send_data HTTP.get(@iiif_url).body, type: 'image/jpeg', x_sendfile: true, disposition: 'inline'
  end

  def info
    @iiif_url = "#{ENV['PROXIED_IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}/info.json"
    Rails.logger.info("Trying to proxy info from #{@iiif_url}")
    response.set_header('Access-Control-Allow-Origin', '*')
    send_data HTTP.get(@iiif_url).body, type: 'application/json', x_sendfile: true, disposition: 'inline'
  end

  def iiif_url
    raise "PROXIED_IIIF_SERVER_URL must be set" unless ENV['PROXIED_IIIF_SERVER_URL']
    "#{ENV['PROXIED_IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
  end

  def manifest
    headers['Access-Control-Allow-Origin'] = '*'
    render json: ManifestBuilderService.build_manifest(identifier)
  end

  # IIIF URLS really do not like extra slashes. Ensure that we only add a slash after the
  # PROXIED_IIIF_SERVER_URL value if it is needed
  def trailing_slash_fix
    '/' unless ENV['PROXIED_IIIF_SERVER_URL'].last == '/'
  end

  def identifier
    params["identifier"]
  end

  def region
    params["region"]
  end

  def size
    params["size"]
  end

  def rotation
    params["rotation"]
  end

  def quality
    params["quality"]
  end

  def format
    params["format"]
  end
end
