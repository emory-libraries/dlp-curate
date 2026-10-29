# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0]
# Hyrax 5 changed DEFAULT_ID from "admin_set/default" to "admin_set_default".
# Without the hyrax_default_administrative_set table (or when it is empty),
# find_or_create_default_admin_set never looks up the legacy ID and mints a
# second "Default Admin Set". Prefer any existing default before creating.
module Hyrax
  module AdminSetCreateServiceOverride
    LEGACY_DEFAULT_ID = 'admin_set/default'

    def find_or_create_default_admin_set
      find_known_default_admin_set || super
    end

    private

      def find_known_default_admin_set
        ids_to_try.each do |id|
          resource = find_admin_set_by_id(id)
          next unless resource

          remember_default_id(resource)
          return resource
        end
        nil
      end

      def ids_to_try
        persisted_id = Hyrax::DefaultAdministrativeSet.first&.default_admin_set_id if Hyrax::DefaultAdministrativeSet.save_supported?
        [persisted_id, LEGACY_DEFAULT_ID, Hyrax::AdminSetCreateService::DEFAULT_ID].compact.uniq
      end

      def find_admin_set_by_id(id)
        Hyrax.query_service.find_by(id:)
      rescue Valkyrie::Persistence::ObjectNotFoundError, Hyrax::ObjectNotFoundError, Ldp::BadRequest, Ldp::HttpError, Faraday::Error
        nil
      end

      def remember_default_id(resource)
        return unless Hyrax::DefaultAdministrativeSet.save_supported?

        Hyrax::DefaultAdministrativeSet.update(default_admin_set_id: resource.id.to_s)
        Hyrax.config.reset_default_admin_set
      end
  end
end
