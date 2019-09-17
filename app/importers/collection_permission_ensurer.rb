# frozen_string_literal: true

class CollectionPermissionEnsurer
  AGENT_TYPE = 'group'

  def initialize(collection:, access_permissions:)
    access_permissions.each do |access_permission, groups|
      hpt = find_or_create_permission_template(collection)
      groups.select! { |group| Role.exists?(name: group) }
      groups.each do |group|
        next if group_rights_exists?(hyrax_permission_template: hpt, access_permission: access_permission, group: group)
        hpta = Hyrax::PermissionTemplateAccess.new
        hpta.permission_template_id = hpt.id
        hpta.agent_type = AGENT_TYPE
        hpta.agent_id = group
        hpta.access = access_permission
        hpta.save
      end
      update_collection(collection, hpt)
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

    def group_rights_exists?(hyrax_permission_template:, access_permission:, group:)
      existing_hpta = Hyrax::PermissionTemplateAccess.where(
        permission_template_id: hyrax_permission_template.id,
        agent_type: AGENT_TYPE,
        agent_id: group,
        access: access_permission
      ).count
      return true if existing_hpta.positive?
      false
    end

    def update_collection(collection, permission_template)
      collection.update!(read_groups: permission_template.agent_ids_for(access: 'view', agent_type: 'group') + ["public"],
                         edit_groups: permission_template.agent_ids_for(access: 'manage', agent_type: 'group'))
    end
end
