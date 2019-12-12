# frozen_string_literal: true

module CustomPermissionBadge
  private

    # We are overriding this method from Hyrax because we do not want to display the
    # institution name in the Authenticated permission badge
    def text
      I18n.t("hyrax.visibility.#{@visibility}.text")
    rescue
      @visibility.to_s
    end
end
