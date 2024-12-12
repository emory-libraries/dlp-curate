# frozen_string_literal: true

# Blacklight IIIF Search v1.0.0 Override: per this application's instructions,
#   this module must be overridden if coordinates will be provided within the results
#   of this Gem's search API. It was also necessary to override #annotation_id and
#   #canvas_uri_for_annotation so that we can match the format of each canvas' @id
#   url value.

# customizable behavior for IiifSearchAnnotation
module BlacklightIiifSearch
  module AnnotationBehavior
    ##
    # Create a URL for the annotation
    # @return [String]
    def annotation_id
      "#{emory_iiif_id_url}/canvas/#{document[:id]}/annotation/#{hl_index}"
    end

    ##
    # Create a URL for the canvas that the annotation refers to
    # @return [String]
    def canvas_uri_for_annotation
      "#{emory_iiif_id_url}/canvas/#{document[:id]}" + coordinates
    end

    # NOTE: The methods #coordinates, #fetch_and_parse_coords, and #default_coords below are largely derived
    #   from IiifPrint's (v3.0.1) IiifPrint::BlacklightIiifSearch::AnnotationDecorator module methods of the
    #   same name. The methods have been refactored to function according to our expectations. The IiifPrint Gem
    #   application is licensed under the Apache License 2.0. At the time of adopting this licensed work into
    #   this application, Commercial use, Modification, and Private use were listed under this Gem's Permissions.
    #   The referenced License can be found here:
    #   https://github.com/scientist-softserv/iiif_print/blob/v3.0.1/LICENSE

    ##
    # return a string like "#xywh=100,100,250,20"
    # corresponding to coordinates of query term on image
    # @return [String]
    def coordinates
      coords_json = fetch_and_parse_coords
      return default_coords unless coords_json.present? && coords_json['coords'].present? && query.present?

      query_terms = query.split(' ').map(&:downcase)
      matches = coords_json['coords'].select do |k, _v|
        k.downcase =~ /(#{query_terms.join('|')})/
      end
      coords_array = matches&.values&.flatten(1)&.[](hl_index)

      coords_array.present? ? "#xywh=#{coords_array.join(',')}" : default_coords
    end

    private

      ##
      # a default set of coordinates
      # @return [String]
      def default_coords
        '#xywh=0,0,0,0'
      end

      ##
      # return the JSON word-coordinates file contents
      # @return [JSON]
      def fetch_and_parse_coords
        coords = document['alto_xml_tesi']
        return nil if coords.blank?
        begin
          JSON.parse(coords)
        rescue JSON::ParserError
          nil
        end
      end

      def emory_iiif_id_url
        "http://#{ENV['HOSTNAME'] || 'localhost:3000'}/iiif/#{parent_document[:id]}/manifest"
      end
  end
end
