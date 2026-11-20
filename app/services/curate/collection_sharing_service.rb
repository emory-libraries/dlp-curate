# frozen_string_literal: true

module Curate
  ##
  # Gives a work the sharing of the collection it was deposited in, as the AF
  # CollectionsMembershipActor and ApplyPermissionTemplateActor do: when the work
  # belongs to exactly one collection whose type shares with new works, the
  # collection's managers get edit access and its viewers read access. Its
  # depositors get nothing on the work. Grants are only ever added.
  class CollectionSharingService
    class << self
      # @param work [Hyrax::Work, ActiveFedora::Base]
      # @return [Hyrax::PermissionTemplate, nil] the template of the collection to share
      def template_for(work)
        return unless work.respond_to?(:member_of_collection_ids)

        collection_ids = Array(work.member_of_collection_ids).compact.map(&:to_s).uniq
        return unless collection_ids.size == 1

        collection = Hyrax.query_service.find_by(id: collection_ids.first)
        return unless Hyrax::CollectionType.for(collection:).share_applies_to_new_works?

        Hyrax::PermissionTemplate.find_by(source_id: collection_ids.first)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      # Adds the grants to a work that is about to be saved; the caller saves its ACL.
      # @return [Boolean] whether a collection's sharing applies to the work
      def apply(work)
        template = template_for(work)
        return false unless template

        Hyrax::PermissionTemplateApplicator.apply(template).to(model: work)
      end

      # Adds the grants to a saved work and its FileSets, saving and reindexing the ones that change.
      # @param dry_run [Boolean] report what would change without saving
      # @return [Array] the work and FileSets that were (or would be) given grants
      def share_with_saved(work, dry_run: false)
        template = template_for(work)
        return [] unless template

        [work, *file_sets_for(work)].select { |resource| add_grants(resource, template, dry_run:) }
      end

      private

        def file_sets_for(work)
          return work.file_sets.to_a if work.is_a?(ActiveFedora::Base)

          Hyrax.custom_queries.find_child_file_sets(resource: work).to_a
        end

        def add_grants(resource, template, dry_run:)
          before = grants(resource)
          Hyrax::PermissionTemplateApplicator.apply(template).to(model: resource)
          return false if grants(resource) == before

          save(resource) unless dry_run
          true
        end

        def grants(resource)
          [resource.edit_groups, resource.edit_users, resource.read_groups, resource.read_users].map { |agents| agents.to_a.sort }
        end

        def save(resource)
          return resource.save! if resource.is_a?(ActiveFedora::Base)

          resource.permission_manager.acl.save
          Hyrax.index_adapter.save(resource:)
        end
    end
  end
end
