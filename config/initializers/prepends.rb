# frozen_string_literal: true
# [Hyrax-overwrite-v3.3.0]
require_relative '../prepends/custom_access_rights'

Hydra::AccessControls::AccessRight.prepend(CustomAccessRights)
