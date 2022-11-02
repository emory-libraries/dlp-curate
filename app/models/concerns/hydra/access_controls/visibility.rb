# frozen_string_literal: true
# Hydra::AccessControls v11.0.7 Override: our initializer prepends stopped working,
#   so a straight override is necessary.

module Hydra::AccessControls
  module Visibility
    extend ActiveSupport::Concern

    def visibility=(value)
      return if value.nil?
      # only set explicit permissions
      case value
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        public_visibility!
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        registered_visibility!
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        private_visibility!
      when ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES
        low_res_visibility!
      when ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW
        emory_low_visibility!
      when ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
        rose_high_visibility!
      else
        raise ArgumentError, "Invalid visibility: #{value.inspect}"
      end
    end

    def visibility
      if read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      elsif read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      elsif read_groups.include? ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES
        ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES
      elsif read_groups.include? ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW
        ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW
      elsif read_groups.include? ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
        ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
      else
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end

    def visibility_changed?
      !!@visibility_will_change
    end

    private

      # Override represented_visibility if you want to add another visibility that is
      # represented as a read group (e.g. on-campus)
      # @return [Array] a list of visibility types that are represented as read groups
      def represented_visibility
        [AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
         AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end

      def visibility_will_change!
        @visibility_will_change = true
      end

      def public_visibility!
        visibility_will_change! unless visibility == AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        remove_groups = represented_visibility - [AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        set_read_groups([AccessRight::PERMISSION_TEXT_VALUE_PUBLIC], remove_groups)
      end

      def registered_visibility!
        visibility_will_change! unless visibility == AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        remove_groups = represented_visibility - [AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
        set_read_groups([AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED], remove_groups)
      end

      def private_visibility!
        visibility_will_change! unless visibility == AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        set_read_groups([], represented_visibility)
      end

      def low_res_visibility!
        visibility_will_change! unless visibility == ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES
        remove_groups = represented_visibility - [::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES]
        set_read_groups([::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES], remove_groups)
      end

      def emory_low_visibility!
        visibility_will_change! unless visibility == ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW
        remove_groups = represented_visibility - [::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW]
        set_read_groups([::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW], remove_groups)
      end

      def rose_high_visibility!
        visibility_will_change! unless visibility == ::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
        remove_groups = represented_visibility - [::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH]
        set_read_groups([::Curate::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH], remove_groups)
      end
  end
end
