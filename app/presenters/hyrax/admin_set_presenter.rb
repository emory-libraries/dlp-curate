# frozen_string_literal: true
# [Hyrax-overwrite-v3.3.0]
# Changes behavior of total_viewable_items to match total_items
module Hyrax
  class AdminSetPresenter < CollectionPresenter
    include ManagedAccess
    ##
    # @return [Boolean] true if there are items
    def any_items?
      total_items.positive?
    end

    def total_items
      Hyrax::SolrService.count("{!field f=isPartOf_ssim}#{id}")
    end

    def total_viewable_items
      total_items
    end

    # AdminSet cannot be deleted if default set or non-empty
    def disable_delete?
      default_set? || any_items?
    end

    # Message to display if deletion is disabled
    def disabled_message
      rreturn I18n.t('hyrax.admin.admin_sets.delete.error_default_set') if default_set?
      I18n.t('hyrax.admin.admin_sets.delete.error_not_empty') if any_items?
    end

    def collection_type
      @collection_type ||= Hyrax::CollectionType.find_or_create_admin_set_type
    end

    def show_path
      Hyrax::Engine.routes.url_helpers.admin_admin_set_path(id, locale: I18n.locale)
    end

    def available_parent_collections(*)
      []
    end

    # Determine if the user can perform batch operations on this admin set.  Currently, the only
    # batch operation allowed is deleting, so this is equivalent to checking if the user can delete
    # the admin set determined by criteria...
    # * user must be able to edit the admin set to be able to delete it
    # * the admin set itself must be able to be deleted (i.e., there cannot be any works in the admin set)
    # @return Boolean true if the user can perform batch actions; otherwise, false
    def allow_batch?
      return false unless current_ability.can?(:edit, solr_document)
      !disable_delete?
    end

    private

      def default_set?
        Hyrax::AdminSetCreateService.default_admin_set?(id: id)
      end
  end
end
