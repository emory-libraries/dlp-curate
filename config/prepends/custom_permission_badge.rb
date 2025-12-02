# frozen_string_literal: true
# [Hyrax-overwrite-v5.2.0] We do not want to display the institution name in the Authenticated permission badge

module CustomPermissionBadge
  private

    def text
      visibility_key = @visibility || 'unknown'
      I18n.t("hyrax.visibility.#{visibility_key}.text")
    rescue
      @visibility.to_s
    end
end
