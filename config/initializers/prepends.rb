require_relative '../prepends/custom_access_rights'
require_relative '../prepends/custom_visibility'

Hydra::AccessControls::AccessRight.prepend(CustomAccessRights)
Hydra::AccessControls::Visibility.prepend(CustomVisibility)
