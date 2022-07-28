# frozen_string_literal: true

require_relative '../prepends/custom_permission_badge'

Hyrax::PermissionBadge.prepend(CustomPermissionBadge)
