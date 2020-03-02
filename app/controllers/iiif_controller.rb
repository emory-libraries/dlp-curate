# frozen_string_literal: true

class IiifController < ApplicationController
  def self.max_pixels_for_low_res
    ENV['MAX_PIXELS_FOR_LOW_RES'] || 400
  end

  def show
    @iiif_url ||= iiif_url
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
    solr_doc = SolrDocument.find(identifier)
    render json: ManifestBuilderService.build_manifest(identifier, presenter(solr_doc))
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

  # Calculate the size parameter to pass along to Cantaloupe
  # For any object with low resolution requirements, check that the requested size is smaller than the configured max size
  def size
    return params["size"] if visibility == "open"
    if visibility == "low_res"
      return ",#{IiifController.max_pixels_for_low_res}" if size_requested_larger_than_allowed?
      params["size"]
    end
    params["size"]
  end

  def size_requested_larger_than_allowed?
    return true if params["size"] == "full"
    dimensions = params["size"].split(",")
    dimensions = dimensions.reject(&:empty?).map(&:to_i).map { |c| c > IiifController.max_pixels_for_low_res }
    return true if dimensions.include?(true)
    false
  rescue
    true
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

  def visibility
    @visibility ||= fetch_visibility
  end

  # Sometimes we will need to look up visibility from solr.
  # If this goes wrong for any reason, default to "restricted"
  # Note that Emory's cantaloupe is using SHA1 checksums to look up images, NOT work IDs
  def fetch_visibility
    response = Blacklight.default_index.connection.get 'select', params: { q: "digest_ssim:urn:sha1:#{identifier}" }
    visibility = response["response"]["docs"][0]["visibility_ssi"]
    return visibility unless visibility.nil? || visibility.empty?
    ["restricted"]
  rescue
    ["restricted"]
  end

  private

    # @param [SolrDocument] document
    def presenter(document)
      ability = ManifestAbility.new
      Hyrax::CurateGenericWorkPresenter.new(document, ability)
    end
end
