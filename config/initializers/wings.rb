# frozen_string_literal: true
# rubocop:disable Metrics/BlockLength

# Freyja setup adapted from hyku
if Hyrax.config.valkyrie_transition?
  Rails.application.config.after_initialize do
    [ # List AF work models
      CurateGenericWork
    ].each do |klass|
      Wings::ModelRegistry.register("#{klass}Resource".constantize, klass)
      # we register itself so we can pre-translate the class in Freyja instead of having to translate in each query_service
      Wings::ModelRegistry.register(klass, klass)
    end
    Wings::ModelRegistry.register(Collection, Collection)
    Wings::ModelRegistry.register(CollectionResource, Collection)
    Wings::ModelRegistry.register(AdminSet, AdminSet)
    Wings::ModelRegistry.register(AdminSetResource, AdminSet)
    Wings::ModelRegistry.register(FileSet, FileSet)
    Wings::ModelRegistry.register(Hyrax::FileSet, FileSet)
    Wings::ModelRegistry.register(FileSetResource, FileSet)
    Wings::ModelRegistry.register(Hydra::PCDM::File, Hydra::PCDM::File)
    Wings::ModelRegistry.register(Hyrax::FileMetadata, Hydra::PCDM::File)

    Valkyrie::MetadataAdapter.register(
      Freyja::MetadataAdapter.new,
      :freyja
    )
    Valkyrie.config.metadata_adapter = :freyja
    Hyrax.config.query_index_from_valkyrie = true
    Hyrax.config.index_adapter = :solr_index

    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::VersionedDisk.new(base_path:  Rails.root.join("storage", "files"),
                                           file_mover: FileUtils.method(:cp)),
      :disk
    )
    Valkyrie.config.storage_adapter  = :disk
    Valkyrie.config.indexing_adapter = :solr_index

    # load all the sql based custom queries
    [
      Hyrax::CustomQueries::Navigators::CollectionMembers,
      Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator,
      Hyrax::CustomQueries::Navigators::ParentCollectionsNavigator,
      Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator,
      Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
      Hyrax::CustomQueries::Navigators::FindFiles,
      Hyrax::CustomQueries::FindAccessControl,
      Hyrax::CustomQueries::FindCollectionsByType,
      Hyrax::CustomQueries::FindFileMetadata,
      Hyrax::CustomQueries::FindIdsByModel,
      Hyrax::CustomQueries::FindManyByAlternateIds,
      Hyrax::CustomQueries::FindModelsByAccess,
      Hyrax::CustomQueries::FindCountBy,
      Hyrax::CustomQueries::FindByDateRange,
      Hyrax::CustomQueries::Navigators::ParentWorkNavigator,
      Curate::CustomQueries::FindBySourceIdentifier,
      Curate::CustomQueries::FindParentWorks
    ].each do |handler|
      Hyrax.query_service.services[0].custom_queries.register_query_handler(handler)
    end

    # Register find_by_model_and_property_value with find_single_or_nil strategy so
    # Freyja's composite dispatch returns nil (not ObjectNotFoundError) when not found.
    Goddess::CustomQueryContainer.known_custom_queries_and_their_strategies[:find_by_model_and_property_value] = :find_single_or_nil
    Goddess::CustomQueryContainer.known_custom_queries_and_their_strategies[:find_parent_works] = :find_multiple
  end

  Rails.application.config.to_prepare do
    AdminSetResource.class_eval do
      attribute :internal_resource, Valkyrie::Types::Any.default("AdminSet"), internal: true
    end

    CollectionResource.class_eval do
      attribute :internal_resource, Valkyrie::Types::Any.default("Collection"), internal: true
    end

    CurateGenericWorkResource.class_eval do
      attribute :internal_resource, Valkyrie::Types::Any.default("CurateGenericWork"), internal: true
    end

    FileSetResource.class_eval do
      attribute :internal_resource, Valkyrie::Types::Any.default("FileSet"), internal: true
    end

    Valkyrie.config.resource_class_resolver = lambda do |resource_klass_name|
      # TODO: Can we use some kind of lookup.
      klass_name = resource_klass_name.gsub(/^Wings\((.+)\)$/, '\1')
      klass_name = klass_name.gsub(/Resource$/, '')
      if %w[
        CurateGenericWork
      ].include?(klass_name)
        "#{klass_name}Resource".constantize
      elsif 'Collection' == klass_name
        CollectionResource
      elsif 'AdminSet' == klass_name
        AdminSetResource
        # Without this mapping, we'll see cases of Postgres Valkyrie adapter attempting to write to
        # Fedora.  Yeah!
      elsif 'Hydra::AccessControl' == klass_name
        Hyrax::AccessControl
      elsif 'FileSet' == klass_name
        FileSetResource
      elsif 'Hydra::AccessControls::Embargo' == klass_name
        Hyrax::Embargo
      elsif 'Hydra::AccessControls::Lease' == klass_name
        Hyrax::Lease
      elsif 'Hydra::PCDM::File' == klass_name
        Hyrax::FileMetadata
      else
        klass_name.constantize
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end

# Register app-specific custom queries on the Wings adapter so they are
# available in both Freyja (valkyrie_transition) and Wings-only (test) modes.
Rails.application.config.after_initialize do
  [Curate::CustomQueries::FindParentWorks].each do |handler|
    Hyrax.query_service.custom_queries.register_query_handler(handler)
  rescue StandardError
    nil
  end
end
