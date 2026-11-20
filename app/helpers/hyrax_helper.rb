# frozen_string_literal: true

module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior
  include NewspaperWorks::NewspaperWorksHelperBehavior

  # [Hyrax-override-hyrax-v5.2.0] The groups offered on a work's Sharing tab. Hyrax offers
  # admins only the role mapper's groups (config/role_map.yml), but Curate's groups are
  # the roles managed at /roles. Other users are offered their own groups, as in Hyrax.
  def available_user_groups(ability:)
    return super unless ability.admin?

    (Role.pluck(:name) + super).uniq.sort
  end
end
