# frozen_string_literal: true

class IiifController < ApplicationController
  def show
    @iiif_url = iiif_url
    send_data HTTP.get(@iiif_url).body, type: 'image/jpeg', x_sendfile: true, disposition: 'inline'
  end

  def iiif_url
    raise "PROXIED_IIIF_SERVER_URL must be set" unless ENV['PROXIED_IIIF_SERVER_URL']
    "#{ENV['PROXIED_IIIF_SERVER_URL']}/#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
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
