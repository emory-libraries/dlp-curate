# frozen_string_literal: true
# @markup markdown
# The IIIF Controller
#1. Proxies image requests to the Cantaloupe IIIF server in order to enforce Emory's visibility requirements. It does so by
#  a. Allowing or denying image requests, based on the user's authentication and the image's visibility.
#  b. For images with low resolution visibility, e.g. Public Low Res and Emory Low Download, the IIIF Controller rewrites the IIIF requests, to limit the maximum size for full size images and for a given region of an image.
#
#2. Provides a thumbnail path for Lux, which also enforces Emory visibility requirements.
#3. Proxies the info.json and the manifest for Curate.

class IiifController < ApplicationController
  skip_before_action :authenticate_user!

  def self.max_pixels_for_low_res
    ENV['MAX_PIXELS_FOR_LOW_RES'] || 400
  end

  def self.min_tile_size_for_low_res
    ENV['MIN_TILE_SIZE_FOR_LOW_RES'] || 800
  end

  def show
    if user_signed_in?
      send_image
    else
      evaluate_visibility
    end
  end

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

  def evalute_thumbnail_visibility
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

  # The identifier that is provided in the URL is the file set ID for the representative image
  def thumbnail
    if user_signed_in?
      send_thumbnail
    else
      evalute_thumbnail_visibility
    end
  end

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

  def user_ip_rose_reading_room?
    rose_reading_room_ips.include? user_ip
  rescue
    false
  end

  def user_ip
    return request.headers["X-Forwarded-For"] if request.headers["X-Forwarded-For"]
    return request.headers["REMOTE_ADDR"] if request.headers["REMOTE_ADDR"]
  end

  def rose_reading_room_ips
    reading_room_ips["all_reading_room_ips"]["rose_reading_room_ip_list"]
  end

  def reading_room_ips
    @reading_room_ips ||= reading_room_ips_yaml.with_indifferent_access
  end

  def reading_room_ips_yaml
    YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "reading_room_ips.yml"))).result, [], [], true)
  end

  def send_image
    @iiif_url ||= iiif_url
    Rails.logger.info("Trying to proxy image from #{@iiif_url}")
    response.set_header('Access-Control-Allow-Origin', '*')
    stream_response(response)
  end

  def valid_cookie?
    if IiifAuthService.decrypt_cookie(cookies["bearer_token"]) == "This is a token value"
      true
    else
      false
    end
  end

  def info
    @iiif_url = "#{ENV['PROXIED_IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}/info.json"
    Rails.logger.info("Trying to proxy info from #{@iiif_url}")
    response.set_header('Access-Control-Allow-Origin', '*')
    @info_original = HTTP.get(@iiif_url).to_s
    @info_public_iiif = rewrite_iiif_base_uri(@info_original)
    send_data @info_public_iiif, type: 'application/json', x_sendfile: true, disposition: 'inline'
  end

  def rewrite_iiif_base_uri(info_original)
    parsed_json = JSON.parse(info_original)
    public_base_uri = "#{ENV['IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}"
    parsed_json["@id"] = public_base_uri
    JSON.generate(parsed_json)
  end

  def iiif_url
    raise "PROXIED_IIIF_SERVER_URL must be set" unless ENV['PROXIED_IIIF_SERVER_URL']
    "#{ENV['PROXIED_IIIF_SERVER_URL']}#{trailing_slash_fix}#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
  end

  def manifest
    headers['Access-Control-Allow-Origin'] = '*'
    solr_doc = SolrDocument.find(identifier)
    render json: ManifestBuilderService.build_manifest(presenter: presenter(solr_doc), curation_concern: CurateGenericWork.find(identifier))
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
    return params["region"] if visibility == "open"
    return params["region"] if params["region"] == "full"
    low_res_adjusted_region if visibility == "low_res" || visibility == "emory_low"
  rescue
    "0,0,#{IiifController.min_tile_size_for_low_res},#{IiifController.min_tile_size_for_low_res}"
  end

  def low_res_adjusted_region
    return params["region"] unless region_requested_larger_than_allowed?
    coordinates = params["region"].split(',')
    x = coordinates[0]
    y = coordinates[1]
    "#{x},#{y},#{IiifController.min_tile_size_for_low_res},#{IiifController.min_tile_size_for_low_res}"
  end

  def region_requested_larger_than_allowed?
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

  def thumbnail_visibility
    @thumbnail_visibility ||= fetch_thumbnail_visibility
  end

  def fetch_thumbnail_visibility
    response = Blacklight.default_index.connection.get 'select', params: { q: "id:#{identifier}" }
    visibility = response["response"]["docs"][0]["visibility_ssi"]
    return visibility unless visibility.nil? || visibility.empty?
    ["restricted"]
  rescue
    ["restricted"]
  end

  def visibility
    @visibility ||= fetch_visibility
  end

  # Sometimes we will need to look up visibility from solr.
  # If this goes wrong for any reason, default to "restricted"
  # Note that Emory's cantaloupe is using SHA1 checksums to look up images, NOT work IDs
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
