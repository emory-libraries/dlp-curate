# frozen_string_literal: true

# NOTE: This model is largely derived from IiifPrint's (v3.0.1)
#   IiifPrint::TextExtraction::WordCoordsBuilder class. Minor changes have been made to bring
#   the code into Rubocop compliancy. The IiifPrint Gem application is licensed under the
#   Apache License 2.0. At the time of adopting this licensed work into this application,
#   Commercial use, Modification, and Private use were listed under this Gem's Permissions.
#   The referenced License can be found here:
#   https://github.com/scientist-softserv/iiif_print/blob/v3.0.1/LICENSE
module Curate
  # Module for text extraction (OCR or otherwise)
  module TextExtraction
    class WordCoordsBuilder
      # @params words [Array<Hash>] an array of hash objects that have the keys `:word` and `:coordinates`.
      # @params width [Integer] the width of the "canvas" on which the words appear.
      # @params height [Integer] the height of the "canvas" on which the words appear.
      # @return [String] a JSON encoded string.
      def self.json_coordinates_for(words:, width: nil, height: nil)
        new(words, width, height).to_json
      end

      def initialize(words, width = nil, height = nil)
        @words = words
        @width = width
        @height = height
      end

      # Output JSON flattened word coordinates
      #
      # @return [String] JSON serialization of flattened word coordinates
      def to_json
        coordinates = {}
        @words.each do |w|
          word_chars = w[:word]
          word_coords = w[:coordinates]
          if coordinates[word_chars]
            coordinates[word_chars] << word_coords
          else
            coordinates[word_chars] = [word_coords]
          end
        end
        payload = { width: @width, height: @height, coords: coordinates }
        JSON.generate(payload)
      end
    end
  end
end
