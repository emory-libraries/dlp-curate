# frozen_string_literal: true

# [hydra-access-controls-overwrite-v11.0.7] L#7-60 contains customizations to our needs.
module Hydra::AccessControls::Visibility
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
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
    when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES
      low_res_visibility!
    when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW
      emory_low_visibility!
    when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
      rose_high_visibility!
    else
      raise ArgumentError, "Invalid visibility: #{value.inspect}"
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength

  def visibility
    ret_val = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    visibility_array.each do |vr|
      next unless read_groups.include? vr[:test_value]
      ret_val = vr[:return_value]
      break
    end
    ret_val
  end

  def low_res_visibility!
    common_visibility_processor(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES)
  end

  def emory_low_visibility!
    common_visibility_processor(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW)
  end

  def rose_high_visibility!
    common_visibility_processor(Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH)
  end

  def visibility_changed?
    !!@visibility_will_change
  end

  private

    def common_visibility_processor(common_visibility)
      visibility_will_change! unless visibility == common_visibility
      remove_groups = represented_visibility - [common_visibility]
      set_read_groups([common_visibility], remove_groups)
    end

    def differing_return_visibility_processor(test_visibility, return_visibility)
      visibility_will_change! unless visibility == test_visibility
      remove_groups = represented_visibility - [return_visibility]
      set_read_groups([return_visibility], remove_groups)
    end

    # Override represented_visibility if you want to add another visibility that is
    # represented as a read group (e.g. on-campus)
    # @return [Array] a list of visibility types that are represented as read groups
    def represented_visibility
      [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
       Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
    end

    def visibility_will_change!
      @visibility_will_change = true
    end

    def public_visibility!
      differing_return_visibility_processor(
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
      )
    end

    def registered_visibility!
      differing_return_visibility_processor(
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
        Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
      )
    end

    def private_visibility!
      visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      set_read_groups([], represented_visibility)
    end

    def visibility_array
      [
        { test_value:   Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,
          return_value: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC },
        { test_value:   Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED,
          return_value: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED },
        { test_value:   Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES,
          return_value: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES },
        { test_value:   Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW,
          return_value: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW },
        { test_value:   Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH,
          return_value: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH }
      ]
    end
end
