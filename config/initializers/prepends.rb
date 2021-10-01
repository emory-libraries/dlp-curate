# frozen_string_literal: true

require_relative '../prepends/custom_access_rights'

Hydra::AccessControls::AccessRight.prepend(CustomAccessRights)
