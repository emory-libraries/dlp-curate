# frozen_string_literal: true

module CustomVisibility
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

  def visibility
    if read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    elsif read_groups.include? Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    elsif read_groups.include? Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES
    elsif read_groups.include? Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW
    elsif read_groups.include? Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
    else
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
  end

  def low_res_visibility!
    visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES
    remove_groups = represented_visibility - [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LOW_RES]
    set_read_groups([Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC], remove_groups)
  end

  def emory_low_visibility!
    visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW
    remove_groups = represented_visibility - [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMORY_LOW]
    set_read_groups([Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED], remove_groups)
  end

  def rose_high_visibility!
    visibility_will_change! unless visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH
    remove_groups = represented_visibility - [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH]
    set_read_groups([Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ROSE_HIGH], remove_groups)
  end
end
