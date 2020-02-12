# frozen_string_literal: true

# Proxy IIIF requests so we can protect IIIF images using Curate's rules around
# object visibility.
class IiifController < ApplicationController
  MAX_SIZE = ENV['MAX_LOW_RES_PIXELS'] || "400"

  # Issue a IIIF image request to cantaloupe and return the result
  def show
    check_for_required_environment_variables
    @iiif_url = iiif_image_url
    return nil if @iiif_url.nil?
    send_data HTTP.get(@iiif_url).body, type: 'image/jpeg', x_sendfile: true, disposition: 'inline'
  end

  # Issue an info.json request to cantaloupe and return the result
  def info
    check_for_required_environment_variables
    @iiif_url = "#{ENV['PROXIED_IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}/info.json"
    send_data HTTP.get(@iiif_url).body, type: 'application/json', x_sendfile: true, disposition: 'inline'
  end

  def check_for_required_environment_variables
    raise "PROXIED_IIIF_SERVER_URL must be set" unless ENV['PROXIED_IIIF_SERVER_URL']
  end

  # What should the IIIF query actually be?
  # It must be adjusted based on object visibility and whether the user is authenticated
  def iiif_image_url
    visibility = visibility(identifier)
    return nil unless visibility
    adjusted_size = adjust_size(visibility: visibility, size: size)
    "#{ENV['PROXIED_IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}/#{region}/#{adjusted_size}/#{rotation}/#{quality}.#{format}"
  end

  # Given a visibility setting and a size request, adjust the allowed size setting as appropriate
  def adjust_size(visibility:, size:)
    return size if visibility == "open"
    return "#{MAX_SIZE}," if size == "full" && visibility == "low_res"
  end

  # Given a sha1 checksum, find the visibility of the FileSet
  def visibility(sha1)
    response = Blacklight.default_index.connection.get 'select', params: { q: "original_checksum_tesim:urn:sha1:#{sha1}" }[0]
    response["response"]["docs"][0]["visibility_ssi"]
  rescue
    Rails.logger.error "Could not find visibility setting for sha1 value #{sha1}"
    nil
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
