# frozen_string_literal: true

class IiifController < ApplicationController
  def show
    puts params
    @iiif_url = "http://127.0.0.1:8182/iiif/2/#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
    send_data HTTP.get(@iiif_url).body, type: 'image/jpeg', x_sendfile: true, disposition: 'inline'
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
