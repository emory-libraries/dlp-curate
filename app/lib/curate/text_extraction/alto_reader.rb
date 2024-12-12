# frozen_string_literal: true
require 'active_support/core_ext/module/delegation'
require 'json'
require 'nokogiri'

# NOTE: This model is largely derived from IiifPrint's (v3.0.1)
#   IiifPrint::TextExtraction::AltoReader class. Minor changes have been made to bring
#   the code into Rubocop compliancy. The IiifPrint Gem application is licensed under the
#   Apache License 2.0. At the time of adopting this licensed work into this application,
#   Commercial use, Modification, and Private use were listed under this Gem's Permissions.
#   The referenced License can be found here:
#   https://github.com/scientist-softserv/iiif_print/blob/v3.0.1/LICENSE
module Curate
  # Module for text extraction
  module TextExtraction
    # Class to obtain plain text and JSON word-coordinates from ALTO source
    class AltoReader
      attr_accessor :source, :doc_stream
      delegate :text, to: :doc_stream

      # SAX Document Stream class to gather text and word tokens from ALTO
      class AltoDocStream < Nokogiri::XML::SAX::Document
        attr_accessor :text, :words

        def initialize(image_width = nil)
          super()
          # scaling matters:
          @image_width = image_width
          @scaling = 1.0 # pt to px, if ALTO using points
          # plain text buffer:
          @text = ''
          # list of word hash, containing word+coord:
          @words = []
        end

        # Return coordinates from String element attribute hash
        #
        # @param attrs [Hash] hash containing ALTO `String` element attributes.
        # @return [Array] Array of position x, y, width, height in px.
        def s_coords(attrs)
          height = scale_value((attrs['HEIGHT'] || 0).to_i)
          width = scale_value((attrs['WIDTH'] || 0).to_i)
          hpos = scale_value((attrs['HPOS'] || 0).to_i)
          vpos = scale_value((attrs['VPOS'] || 0).to_i)
          [hpos, vpos, width, height]
        end

        def compute_scaling(attrs)
          return if @image_width.nil?
          match = attrs.find { |e| e[0].casecmp?('WIDTH') }
          return if match.empty?
          page_width = match[1].to_i
          return if @image_width == page_width
          @scaling = page_width / @image_width.to_f
        end

        def scale_value(v)
          (v / @scaling).to_i
        end

        # Callback for element start, implementation of which ignores
        #   non-String elements.
        #
        # @param name [String] element name.
        # @param attrs [Array] Array of key, value pair Arrays.
        def start_element(name, attrs = [])
          values = attrs.to_h
          compute_scaling(attrs) if name == 'Page'
          return if name != 'String'
          token = values['CONTENT']
          @text += token
          @words << {
            word:        token,
            coordinates: s_coords(values)
          }
        end

        # Callback for element end, used here to manage endings of lines and
        #   blocks.
        #
        # @param name [String] element name.
        def end_element(name)
          @text += " " if name == 'String'
          @text += "\n" if name == 'TextBlock'
          @text += "\n" if name == 'TextLine'
        end

        # Callback for completion of parsing ALTO, used to normalize generated
        #   text content (strip unneeded whitespace incidental to output).
        def end_document
          # postprocess @text to remove trailing spaces on lines
          @text = @text.split("\n").map(&:strip).join("\n")
          # remove trailing whitespace at end of buffer
          @text.strip!
        end
      end

      # Construct with either path
      #
      # @param xml [String], and process document
      def initialize(xml, image_width = nil, image_height = nil)
        @source = isxml?(xml) ? xml : File.read(xml)
        @image_width = image_width
        @image_height = image_height
        @doc_stream = AltoDocStream.new(image_width)
        parser = Nokogiri::XML::SAX::Parser.new(doc_stream)
        parser.parse(@source)
      end

      # Determine if source parameter is path or xml
      #
      # @param xml [String] either path to xml file or xml source
      # @return [true, false] true if string appears to be XML source, not path
      def isxml?(xml)
        xml.lstrip.start_with?('<')
      end

      # Output JSON flattened word coordinates
      #
      # @return [String] JSON serialization of flattened word coordinates
      def json
        words = @doc_stream.words
        Curate::TextExtraction::WordCoordsBuilder.json_coordinates_for(
          words:  words,
          width:  @image_width,
          height: @image_height
        )
      end
    end
  end
end
