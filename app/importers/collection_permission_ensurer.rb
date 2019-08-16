# frozen_string_literal: true

class CollectionPermissionEnsurer
  AGENT_ID = 'admin'
  AGENT_TYPE = 'group'

  def initialize(collection:, access_permissions:)
    access_permissions.each do |access_permission|
      hpt = find_or_create_permission_template(collection)
      next if repo_admins_have_manage_rights?(hyrax_permission_template: hpt, access_permission: access_permission)
      hpta = Hyrax::PermissionTemplateAccess.new
      hpta.permission_template_id = hpt.id
      hpta.agent_type = AGENT_TYPE
      hpta.agent_id = AGENT_ID
      hpta.access = access_permission
      hpta.save
    end
  end

    private

      def find_or_create_permission_template(collection)
        existing_hpt = Hyrax::PermissionTemplate.where(source_id: collection.id).try(:first)
        return existing_hpt if existing_hpt
        hpt = Hyrax::PermissionTemplate.new
        hpt.source_id = collection.id
        hpt.save
        hpt
      end

      def repo_admins_have_manage_rights?(hyrax_permission_template:, access_permission:)
        existing_hpta = Hyrax::PermissionTemplateAccess.where(
          permission_template_id: hyrax_permission_template.id,
          agent_type: AGENT_TYPE,
          agent_id: AGENT_ID,
          access: access_permission
        ).count
        return true if existing_hpta.positive?
        false
      end
end
