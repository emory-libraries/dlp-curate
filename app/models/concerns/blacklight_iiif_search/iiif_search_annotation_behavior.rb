# frozen_string_literal: true

# customizable behavior for IiifSearchAnnotation
module BlacklightIiifSearch
  module AnnotationBehavior
    ##
    # Create a URL for the annotation
    # @return [String]
    def annotation_id
      "#{controller.solr_document_url(parent_document[:id])}/canvas/#{document[:id]}/annotation/#{hl_index}"
    end

    ##
    # Create a URL for the canvas that the annotation refers to
    # @return [String]
    def canvas_uri_for_annotation
      "#{controller.solr_document_url(parent_document[:id])}/canvas/#{document[:id]}" + coordinates
    end

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
  end
end
