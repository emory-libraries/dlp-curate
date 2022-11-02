# frozen_string_literal: true

module Hyrax
  module AbilityOverrideHelper
    include Hyrax::AbilityHelper

    # [Hyrax-overwrite-v3.4.2] The following method needs to read the bare
    # document's visibility_ssi when rendering the visibility badge.
    def render_visibility_link(document)
      # Admin Sets do not have a visibility property.
      return if document.respond_to?(:admin_set?) && document.admin_set?

      # Anchor must match with a tab in
      # https://github.com/samvera/hyrax/blob/master/app/views/hyrax/base/_guts4form.html.erb#L2
      path = if document.collection?
               hyrax.edit_dashboard_collection_path(document, anchor: 'share')
             else
               edit_polymorphic_path([main_app, document], anchor: 'share')
             end
      link_to(
        visibility_badge(document['visibility_ssi']),
        path,
        id:    "permission_#{document.id}",
        class: 'visibility-link',
        title: "#{t('hyrax.works.form.tab.share')}: #{document.title_or_label}"
      )
    end
  end
end
