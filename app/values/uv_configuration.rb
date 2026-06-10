# frozen_string_literal: true
# Class modeling configuration options for the Universal Viewer
class UvConfiguration < ActiveSupport::HashWithIndifferentAccess
  # Provides the default values for the viewer
  # @return [Hash]
  def self.default_values # rubocop:disable Metrics/MethodLength
    {
      "modules": {
        "footerPanel":        {
          "options": {
            "shareEnabled":      false,
            "downloadEnabled":   false,
            "fullscreenEnabled": false
          }
        },
        "pagingHeaderPanel":  {
          "options": {
            "galleryButtonEnabled":     true,
            "imageSelectionBoxEnabled": false,
            "pageModeEnabled":          false,
            "pagingToggleEnabled":      true
          }
        },
        "moreInfoRightPanel": {
          "content": {
            "manifestHeader": nil
          }
        }
      },
      "options": {
        "pagingEnabled": false
      }
    }
  end # rubocop:enable Metrics/MethodLength

  # Constructor
  # @param values [Hash] configuration options for the Universal Viewer
  # @see https://github.com/UniversalViewer/universalviewer/wiki/Configuration
  def initialize(constructor = {})
    if constructor.respond_to?(:to_hash)
      super()
      update(self.class.default_values.deep_merge(constructor))

      hash = constructor.is_a?(Hash) ? constructor : constructor.to_hash
      self.default = hash.default if hash.default
      self.default_proc = hash.default_proc if hash.default_proc
    else
      super(constructor)
    end
  end
end
