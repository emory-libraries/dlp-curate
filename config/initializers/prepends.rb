# frozen_string_literal: true

require_relative '../prepends/custom_access_rights'
require_relative '../prepends/custom_visibility'
require_relative '../prepends/custom_permission_badge'

Hydra::AccessControls::AccessRight.prepend(CustomAccessRights)
Hydra::AccessControls::Visibility.prepend(CustomVisibility)
Hyrax::PermissionBadge.prepend(CustomPermissionBadge)
