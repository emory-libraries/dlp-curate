# frozen_string_literal: true

module Curate
  class VisibilityMap < Hyrax::VisibilityMap
    CURATE_VISIBILITY_MAP = {
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC => {
        permission: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
        additions:  [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC].freeze,
        deletions:  [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER].freeze
      }.freeze,
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED => {
        permission: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
        additions:  [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED].freeze,
        deletions:  [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER].freeze
      }.freeze,
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE => {
        permission: :PRIVATE,
        additions:  [].freeze,
        deletions:  [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
                     Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER].freeze
      }.freeze,
      Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES => {
        permission: Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
        additions:  [Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES].freeze,
        deletions:  [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
                     Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER].freeze
      }.freeze,
      Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW => {
        permission: Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
        additions:  [Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW].freeze,
        deletions:  [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
                     Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER].freeze
      }.freeze,
      Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH => {
        permission: Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH,
        additions:  [Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH].freeze,
        deletions:  [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
                     Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER].freeze
      }.freeze,
      Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER => {
        permission: Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER,
        additions:  [Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER].freeze,
        deletions:  [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
                     Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
                     Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH].freeze
      }.freeze
    }.freeze

    ##
    # @param map [Hash<String, String>]
    def initialize(map: CURATE_VISIBILITY_MAP)
      super
    end
  end
end
