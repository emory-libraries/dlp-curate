# frozen_string_literal: true
# [Hyrax-override-v5.2.0] Adds our custom visibility options to the Valkyrie visibility processing.

Rails.application.config.to_prepare do
  Hyrax::VisibilityReader.class_eval do
    ##
    # @return [String]
    def read
      if permission_manager.read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
        visibility_map.visibility_for(group: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC)
      elsif permission_manager.read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
        visibility_map.visibility_for(group: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED)
      elsif permission_manager.read_groups.include? ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES
        visibility_map.visibility_for(group: ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES)
      elsif permission_manager.read_groups.include? ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW
        visibility_map.visibility_for(group: ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW)
      elsif permission_manager.read_groups.include? ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
        visibility_map.visibility_for(group: ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH)
      elsif permission_manager.read_groups.include? ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER
        visibility_map.visibility_for(group: ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_IRISH_PARTNER)
      else
        visibility_map.visibility_for(group: :PRIVATE)
      end
    end
  end
end
