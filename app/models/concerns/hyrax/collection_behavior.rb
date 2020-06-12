# frozen_string_literal: true

# [Hyrax-overwrite]
module Hyrax
  module CollectionBehavior
    extend ActiveSupport::Concern
    include Hydra::AccessControls::WithAccessRight
    include Hydra::WithDepositor # for access to apply_depositor_metadata
    include Hydra::AccessControls::Permissions
    include Hyrax::CoreMetadata
    include Hydra::Works::CollectionBehavior
    include Hyrax::Noid
    include Hyrax::HumanReadableType
    include Hyrax::HasRepresentative
    include Hyrax::Permissions
    include Hyrax::CollectionNesting

    included do
      validates_with HasOneTitleValidator
      after_destroy :destroy_permission_template

      self.indexer = Hyrax::CollectionIndexer

      class_attribute :index_collection_type_gid_as, writer: false
      self.index_collection_type_gid_as = [:symbol]

      property :collection_type_gid, predicate: ::RDF::Vocab::SCHEMA.additionalType, multiple: false do |index|
        index.as(*index_collection_type_gid_as)
      end

      # validates that collection_type_gid is present
      validates :collection_type_gid, presence: true

      # Need to define here in order to override setter defined by ActiveTriples
      def collection_type_gid=(new_collection_type_gid)
        raise "Can't modify collection type of this collection" if persisted? && !collection_type_gid_was.nil? && collection_type_gid_was != new_collection_type_gid
        new_collection_type = Hyrax::CollectionType.find_by_gid!(new_collection_type_gid)
        super
        @collection_type = new_collection_type
        collection_type_gid
      end
    end

    delegate(*Hyrax::CollectionType.collection_type_settings_methods, to: :collection_type)

    # Get the collection_type when accessed
    def collection_type
      @collection_type ||= Hyrax::CollectionType.find_by_gid!(collection_type_gid)
    end

    def collection_type=(new_collection_type)
      self.collection_type_gid = new_collection_type.gid
    end

    # This method pulled from v3.0.0.pre.beta3
    # Add members using the members association.
    def add_members(new_member_ids)
      return if new_member_ids.blank?
      members << Hyrax.query_service.custom_queries.find_many_by_alternate_ids(alternate_ids: new_member_ids, use_valkyrie: false)
    end

    # This method pulled from v3.0.0.pre.beta3
    # Add member objects by adding this collection to the objects' member_of_collection association.
    # @param [Enumerable<String>] the ids of the new child collections and works collection ids
    # Valkyrie Version: Wings::CollectionBehavior#add_collections_and_works aliased to #add_member_objects
    #                   lib/wings/models/concerns/collection_behavior.rb
    def add_member_objects(new_member_ids)
      Array(new_member_ids).collect do |member_id|
        member = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: member_id, use_valkyrie: false)
        message = Hyrax::MultipleMembershipChecker.new(item: member).check(collection_ids: id, include_current_members: true)
        if message
          member.errors.add(:collections, message)
        else
          member.member_of_collections << self
          member.save!
        end
        member
      end
    end

    def member_objects
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id}")
    end

    # This method pulled from v3.0.0.pre.beta3
    # Use this query to get the ids of the member objects (since the containment
    # association has been flipped)
    # Valkyrie Version: Wings::CollectionBehavior#child_collections_and_works_ids aliased to #member_object_ids
    #                   lib/wings/models/concerns/collection_behavior.rb
    def member_object_ids
      return [] unless id
      member_objects.map(&:id)
    end

    def to_s
      title.present? ? title.join(' | ') : 'No Title'
    end

    module ClassMethods
      # This governs which partial to draw when you render this type of object
      def _to_partial_path #:nodoc:
        @_to_partial_path ||= begin
          element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
          collection = ActiveSupport::Inflector.tableize(name)
          "hyrax/#{collection}/#{element}"
        end
      end

      # This method updated to match v3.0.0.pre.beta3
      def collection_type_gid_document_field_name
        "collection_type_gid_ssim"
      end
    end

    # @deprecated to be removed in 4.0.0; this feature was replaced with a
    #   hard-coded null implementation
    # @return [Fixnum] 0
    def bytes
      Deprecation.warn('#bytes has been deprecated for removal in Hyrax 4.0.0; ' \
                       'The implementation of the indexed Collection size ' \
                       'feature is extremely inefficient, so it has been removed. ' \
                       'This method now returns a hard-coded `0` for compatibility.')
      0
    end

    # @api public
    # Retrieve the permission template for this collection.
    # @return [Hyrax::PermissionTemplate]
    # @raise [ActiveRecord::RecordNotFound]
    def permission_template
      Hyrax::PermissionTemplate.find_by!(source_id: id)
    end

    # Calculate and update who should have read/edit access to the collections based on who
    # has access in PermissionTemplateAccess
    def reset_access_controls!
      update!(edit_users: permission_template_edit_users, edit_groups: permission_template_edit_groups, read_users: permission_template_read_users,
              read_groups: (permission_template_read_groups + visibility_group).uniq)
    end

    private

      def permission_template_edit_users
        permission_template.agent_ids_for(access: 'manage', agent_type: 'user')
      end

      def permission_template_edit_groups
        permission_template.agent_ids_for(access: 'manage', agent_type: 'group')
      end

      def permission_template_read_users
        (permission_template.agent_ids_for(access: 'view', agent_type: 'user') +
          permission_template.agent_ids_for(access: 'deposit', agent_type: 'user')).uniq
      end

      def permission_template_read_groups
        (permission_template.agent_ids_for(access: 'view', agent_type: 'group') +
          permission_template.agent_ids_for(access: 'deposit', agent_type: 'group')).uniq -
          [::Ability.registered_group_name, ::Ability.public_group_name]
      end

      def visibility_group
        return [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC] if visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        return [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED] if visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        []
      end

      # This method pulled from v3.0.0.pre.beta3
      # Solr field name works use to index member ids
      def member_ids_field
        "member_ids_ssim"
      end

      def destroy_permission_template
        permission_template.destroy
      rescue ActiveRecord::RecordNotFound
        true
      end
  end
end
