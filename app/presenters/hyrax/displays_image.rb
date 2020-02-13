# frozen_string_literal: true
# [Hyrax-overwrite] hardcoding `base_url` on L21 and L36 instead of getting
# it from the request.
require 'iiif_manifest'

module Hyrax
  # This gets mixed into FileSetPresenter in order to create
  # a canvas on a IIIF manifest
  module DisplaysImage
    extend ActiveSupport::Concern

    # Creates a display image only where FileSet is an image.
    #
    # @return [IIIFManifest::DisplayImage] the display image required by the manifest builder.
    def display_image
      return nil unless ::FileSet.exists?(id) && solr_document.image? && current_ability.can?(:read, id)
      # @todo this is slow, find a better way (perhaps index iiif url):
      file_set = ::FileSet.find(id)
      preferred_file = file_set.send(file_set.preferred_file)
      @request_base_url = request_base_url

      url = Hyrax.config.iiif_image_url_builder.call(
        preferred_file.id,
        @request_base_url,
        Hyrax.config.iiif_image_size_default
      )
      # @see https://github.com/samvera-labs/iiif_manifest
      IIIFManifest::DisplayImage.new(url,
                                     width:         640,
                                     height:        480,
                                     iiif_endpoint: iiif_endpoint(preferred_file.id))
    end

    private

      def request_base_url
        base_url = if request.nil?
                     "http://#{ENV['HOSTNAME'] || 'localhost:3000'}"
                   else
                     request.base_url
                   end
        base_url
      end

      def iiif_endpoint(file_id)
        return unless Hyrax.config.iiif_image_server?
        IIIFManifest::IIIFEndpoint.new(
          Hyrax.config.iiif_info_url_builder.call(file_id, @request_base_url),
          profile: Hyrax.config.iiif_image_compliance_level_uri
        )
      end
  end
end
