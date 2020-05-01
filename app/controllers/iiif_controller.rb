# frozen_string_literal: true
#
# The IIIF Controller
# 1. Proxies image requests to the Cantaloupe IIIF server in order to enforce Emory's visibility requirements. It does so by
#  a. Allowing or denying image requests, based on the user's authentication and the image's visibility.
#  b. For images with low resolution visibility, e.g. Public Low Res and Emory Low Download, the IIIF Controller rewrites
# the IIIF requests, to limit the maximum size for full size images and for a given region of an image.
#
# 2. Provides a thumbnail path for Lux, which also enforces Emory visibility requirements.
# 3. Proxies the info.json and the manifest for Curate.

class IiifController < ApplicationController
  skip_before_action :authenticate_user!

  ##
  # Maximum number of pixels per side for low resolution images;
  #   To decrease resolution, decrease this number.
  # @return [Integer]
  def self.max_pixels_for_low_res
    ENV['MAX_PIXELS_FOR_LOW_RES'] || 400
  end

  ##
  # Limits the depth of zoom;
  #   To decrease resolution, increase this number.
  # @return [Integer]
  def self.min_tile_size_for_low_res
    ENV['MIN_TILE_SIZE_FOR_LOW_RES'] || 800
  end

  ##
  # Display an image; this method expects urls to conform to iiif 2.0 standards.
  # Always serves the image for users signed in to Curate; otherwise evaluates access
  # control requirements (see the evaluate_visibility method)
  # @example this method expects urls to conform to iiif 2.0 standards.
  #   a url like /iiif/2/a0f9219f14f071be7e3b872186f3507cfeccd5bf/full/600,/0/default.jpg
  #   will route here and map the following parameters:
  #      "action" => "show",
  #      "identifier" => "a0f9219f14f071be7e3b872186f3507cfeccd5bf",
  #      "region" => "full",
  #      "size" => "600,",
  #      "rotation" => "0",
  #      "quality" => "default",
  #      "format" => "jpg"
  #   Note that region, size may be adjusted based on access control requirements
  def show
    if user_signed_in?
      send_image
    else
      evaluate_visibility
    end
  end

  ##
  # This method handles image requests from users not signed in to Curate.
  # It checks for the visibility of the work based on the visibility_ssi from solr.
  # Depending on the access restrictions of the work, checks either whether the user
  # is logged in to Lux or the user's ip address.
  # Public works (visibility open or low_res) are served to all users.  For works
  # restricted to Emory users, i.e. emory_low or authenticated, a cookie
  # set by Lux is checked.  For works restricted by reading room, i.e. rose_high,
  # the user's ip address is checked against a list of allowed ips.  Restricted works
  # are forbidden here. In case of failure, the default is forbidden.
  def evaluate_visibility
    case visibility
    when "open", "low_res"
      send_image
    when "authenticated", "emory_low" # authenticated is also called "Emory High Download"
      return head :forbidden unless valid_cookie?
      send_image
    when "restricted"
      head :forbidden
    when "rose_high"
      return head :forbidden unless user_ip_rose_reading_room?
      send_image
    else
      head :forbidden
    end
  end

  ##
  # This method handles thumbnail requests for users not signed in to Curate.
  # @see evaluate_visibility
  def evaluate_thumbnail_visibility
    case thumbnail_visibility
    when "open", "low_res"
      send_thumbnail
    when "authenticated", "emory_low" # authenticated is also called "Emory High Download"
      return head :forbidden unless valid_cookie?
      send_thumbnail
    when "rose_high"
      return head :forbidden unless user_ip_rose_reading_room?
      send_thumbnail
    else
      head :forbidden
    end
  end

  ##
  # Display a thumbnail image.
  # The identifier that is provided in the URL is the file set ID for the representative image.
  # Always serves the image for users signed in to Curate; otherwise evaluates access
  # control requirements.
  def thumbnail
    if user_signed_in?
      send_thumbnail
    else
      evaluate_thumbnail_visibility
    end
  end

  ##
  # Stream a thumbnail image.
  # @see send_image
  def send_thumbnail
    response.set_header('Access-Control-Allow-Origin', '*')
    response.headers["Last-Modified"] = Time.now.httpdate.to_s
    response.headers["Content-Type"] = 'image/jpeg'
    response.headers["Content-Disposition"] = 'inline'
    path = Hyrax::DerivativePath.derivative_path_for_reference(identifier, 'thumbnail')
    begin
      IO.foreach(path).each do |buffer|
        response.stream.write(buffer)
      end
    ensure
      response.stream.close
    end
  end

  ##
  # Compares the user's IP address to the list of allowed Rose Reading Room ips
  # to implement the rose_high access restriction.  Defaults to false.
  # @return [Boolean]
  def user_ip_rose_reading_room?
    rose_reading_room_ips.include? user_ip
  rescue
    false
  end

  ##
  # Determine the user's source IP address to allow restrictions based on reading
  # room location.  Depending on system configuration, X-Forwarded-For headers may
  # represent the user's original IP address.
  # @return [String]
  def user_ip
    return request.headers["X-Forwarded-For"] if request.headers["X-Forwarded-For"]
    return request.headers["REMOTE_ADDR"] if request.headers["REMOTE_ADDR"]
  end

  ##
  # From the ip lists imported from reading_room_ips.yml, returns the list of
  # Rose Reading Room IP addresses.
  # @return [Array<String>]
  def rose_reading_room_ips
    reading_room_ips["all_reading_room_ips"]["rose_reading_room_ip_list"]
  end

  def reading_room_ips
    @reading_room_ips ||= reading_room_ips_yaml.with_indifferent_access
  end

  def reading_room_ips_yaml
    YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "reading_room_ips.yml"))).result, [], [], true)
  end

  ##
  # Streams a requested image.
  # Setting the Access-Control-Allow-Origin header is part of the iiif standard
  # and allows images to be viewed from external image viewers.
  def send_image
    @iiif_url ||= iiif_url
    Rails.logger.info("Trying to proxy image from #{@iiif_url}")
    response.set_header('Access-Control-Allow-Origin', '*')
    stream_response(response)
  end

  ##
  # Checks that the bearer_token cookie set in lux decrypts and encodes a date and time
  # within the chosen time window.
  def valid_cookie?
    if (decrypted_cookie_value = IiifAuthService.decrypt_cookie(cookies["bearer_token"]))
      valid_cookie_date?(decrypted_cookie_value)
    else
      false
    end
  end

  ##
  # Checks the decrypted cookie value for a date and time within the coming day.
  # Logs an error and returns false for uninterpretable cookie contents.
  def valid_cookie_date?(decrypted_cookie_value)
    cookie_date = decrypted_cookie_value.to_datetime
    if cookie_date.between?(DateTime.now.utc, 1.day.from_now)
      true
    else
      false
    end
  rescue ArgumentError
    error_message = 'Cookie value is not a date'
    Rails.logger.error error_message
    false
  end

  ##
  # Proxies requests for iiif info.json files.  Per the iiif standard, the info.json
  # is returned regardless of the access restrictions on the object itself.
  def info
    @iiif_url = "#{ENV['PROXIED_IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}/info.json"
    Rails.logger.info("Trying to proxy info from #{@iiif_url}")
    response.set_header('Access-Control-Allow-Origin', '*')
    @info_original = HTTP.get(@iiif_url).to_s
    @info_public_iiif = rewrite_iiif_base_uri(@info_original)
    send_data @info_public_iiif, type: 'application/json', x_sendfile: true, disposition: 'inline'
  end

  ##
  # Replace the proxied iiif server url (cantaloupe) with the public iiif server url
  # (Curate) in the proxied info.json files to direct further queries to the public iiif endpoint
  # @return [String] rewritten json file
  # @param info_original [String] info.json as generated by the proxied iiif server (cantaloupe)
  def rewrite_iiif_base_uri(info_original)
    parsed_json = JSON.parse(info_original)
    public_base_uri = "#{ENV['IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}"
    parsed_json["@id"] = public_base_uri
    JSON.generate(parsed_json)
  end

  ##
  # Constructs a valid iiif url based on the incoming query and access restrictions
  # @see size
  # @see region
  def iiif_url
    raise "PROXIED_IIIF_SERVER_URL must be set" unless ENV['PROXIED_IIIF_SERVER_URL']
    "#{ENV['PROXIED_IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
  end

  def manifest
    headers['Access-Control-Allow-Origin'] = '*'
    solr_doc = SolrDocument.find(identifier)
    render json: ManifestBuilderService.build_manifest(presenter: presenter(solr_doc), curation_concern: CurateGenericWork.find(identifier))
  end

  ##
  # IIIF URLS really do not like extra slashes. Ensure that we only add a slash after the
  # PROXIED_IIIF_SERVER_URL value if it is needed
  def trailing_slash_fix
    '/' unless ENV['PROXIED_IIIF_SERVER_URL'].last == '/'
  end

  ##
  # @return [String] the identifier from the incoming query (sha1 of image)
  def identifier
    params["identifier"]
  end

  ##
  # Adjusts the iiif region parameter from the original query if required by access
  # controls.  Requests for works with resolution restrictions (visibility low_res
  # or emory_low) are adjusted to limit depth of zoom.
  # @see low_res_adjusted_region
  # The region value is unmodified for visibilities without resolution restrictions
  # (open, rose_high, authenticated, restricted).
  #
  # @return [String] a iiif region parameter
  def region
    if params["region"] == "full"
      params["region"]
    else
      case visibility
      when "open", "rose_high", "authenticated", "restricted"
        params["region"]
      when "low_res", "emory_low"
        low_res_adjusted_region
      end
    end
  rescue
    "0,0,#{IiifController.min_tile_size_for_low_res},#{IiifController.min_tile_size_for_low_res}"
  end

  ##
  # Adjusts region values to limit depth of zoom.  If either the width or the
  # height is less than the minimum defined tile size, returns a region with the
  # same starting coordinates and a width and height of the defined minimum tile size.
  def low_res_adjusted_region
    return params["region"] unless region_requested_smaller_than_allowed?
    coordinates = params["region"].split(',')
    x = coordinates[0]
    y = coordinates[1]
    "#{x},#{y},#{IiifController.min_tile_size_for_low_res},#{IiifController.min_tile_size_for_low_res}"
  end

  ##
  # Many small regions could be stitched together to reconstruct a high-resolution file.
  # We limit the smallest regions that can be requested for objects with low resolution
  # visibilities.
  def region_requested_smaller_than_allowed?
    coordinates = params["region"].split(',')
    xsize = coordinates[2]
    ysize = coordinates[3]
    return true if xsize.to_i < IiifController.min_tile_size_for_low_res
    return true if ysize.to_i < IiifController.min_tile_size_for_low_res
    false
  rescue
    true
  end

  # Calculate the size parameter to pass along to Cantaloupe
  # For any object with low resolution requirements, check that the requested size is smaller than the configured max size
  # If the requested image is larger than the configured max size, give the configured max size as the image height.
  def size
    return params["size"] if visibility == "open"
    if visibility == "low_res" || visibility == "emory_low"
      return ",#{IiifController.max_pixels_for_low_res}" if size_requested_larger_than_allowed?
      params["size"]
    end
    params["size"]
  rescue
    IiifController.max_pixels_for_low_res
  end

  ##
  # @return [Boolean] True for full-size images, or if the requested width or
  #    height is greater than the configured maximum pixel size for low resolution
  #    images
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

  # @see fetch_thumbnail_visibility
  def thumbnail_visibility
    @thumbnail_visibility ||= fetch_thumbnail_visibility
  end

  ##
  # Retrieves the visibility_ssi from solr.  The identifier in thumbnail requests
  # is the fileset identifier (unlike iiif image requests)
  # @return [String] the visibility_ssi from solr, or "restricted" if the visibility_ssi
  #   is empty or unavailable.
  def fetch_thumbnail_visibility
    response = Blacklight.default_index.connection.get 'select', params: { q: "id:#{identifier}" }
    visibility = response["response"]["docs"][0]["visibility_ssi"]
    return visibility unless visibility.nil? || visibility.empty?
    ["restricted"]
  rescue
    ["restricted"]
  end

  ##
  # @see fetch_visibility
  def visibility
    @visibility ||= fetch_visibility
  end

  # Sometimes we will need to look up visibility from solr.
  # If this goes wrong for any reason, default to "restricted"
  # Note that Emory's cantaloupe is using SHA1 checksums to look up images, NOT work IDs
  # @return [String]
  def fetch_visibility
    response = Blacklight.default_index.connection.get 'select', params: { q: "sha1_tesim:urn:sha1:#{identifier}" }
    visibility = response["response"]["docs"][0]["visibility_ssi"]
    return visibility unless visibility.nil? || visibility.empty?
    ["restricted"]
  rescue
    ["restricted"]
  end

  private

    def stream_response(response)
      response.headers["Last-Modified"] = Time.now.httpdate.to_s
      response.headers["Content-Type"] = 'image/jpeg'
      response.headers["Content-Disposition"] = 'inline'
      begin
        HTTP.get(@iiif_url).body.each do |buffer|
          response.stream.write(buffer)
        end
      ensure
        response.stream.close
      end
    end

    # @param [SolrDocument] document
    def presenter(document)
      ability = ManifestAbility.new
      Hyrax::CurateGenericWorkPresenter.new(document, ability)
    end
end
