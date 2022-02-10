# frozen_string_literal: true
# [Hyrax-overwrite-v3.1.0] injects custom Globals for access rights.
Hyrax::PermissionBadge.class_eval do
  def text
    I18n.t("hyrax.visibility.#{@visibility}.text")
  rescue
    @visibility.to_s
  end
end
