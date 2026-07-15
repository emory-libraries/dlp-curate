# frozen_string_literal: true
# Bulkrax v8.2.3 override: #search_by_property, #add_child_to_parent_work,
#   #add_resource_to_collection, #create_work, #update_work
#   Adds PreservationEvents integration for work creation/update.

module Bulkrax
  # rubocop:disable Metrics/ClassLength
  class ValkyrieObjectFactory < ObjectFactoryInterface
    include PreservationEvents

    class FileFactoryInnerWorkings < Bulkrax::FileFactory::InnerWorkings
      def remove_file_set(file_set:)
        file_metadata = Hyrax.custom_queries.find_files(file_set:).first
        raise "No file metadata records found for #{file_set.class} ID=#{file_set.id}" unless file_metadata

        Hyrax::VersioningService.create(file_metadata, user, File.new(Bulkrax.removed_image_path))

        ::ValkyrieCreateDerivativesJob.set(wait: 1.minute).perform_later(file_set.id, file_metadata.id)
      end

      def update_file_set(file_set:, uploaded:)
        file_metadata = Hyrax.custom_queries.find_files(file_set:).first
        raise "No file metadata records found for #{file_set.class} ID=#{file_set.id}" unless file_metadata

        uploaded_file = uploaded.file

        return nil if file_metadata.checksum.first == Digest::SHA1.file(uploaded_file.path).to_s

        Hyrax::VersioningService.create(file_metadata, user, uploaded_file)

        ::ValkyrieCreateDerivativesJob.set(wait: 1.minute).perform_later(file_set.id, file_metadata.id)
        nil
      end
    end

    include Bulkrax::FileFactory

    self.file_set_factory_inner_workings_class = Bulkrax::ValkyrieObjectFactory::FileFactoryInnerWorkings

    def self.transactions
      @transactions || Hyrax::Transactions::Container
    end

    def transactions
      self.class.transactions
    end

    ##
    # @!group Class Method Interface

    # Emory override: use += Array() for Valkyrie change tracking instead of <<
    def self.add_child_to_parent_work(parent:, child:)
      return true if parent.member_ids.include?(child.id)

      parent.member_ids += Array(child.id)
      parent.save
    end

    # Emory override: use += Array() for Valkyrie change tracking instead of <<
    def self.add_resource_to_collection(collection:, resource:, user:)
      resource.member_of_collection_ids += Array(collection.id)
      save!(resource:, user:)
    end

    def self.field_multi_value?(field:, model:)
      return false unless field_supported?(field:, model:)

      if model.respond_to?(:schema)
        dry_type = model.schema.key(field.to_sym)
        return true if dry_type.respond_to?(:primitive) && dry_type.primitive == Array

        false
      else
        Bulkrax::ObjectFactory.field_multi_value?(field:, model:)
      end
    end

    def self.field_supported?(field:, model:)
      if model.respond_to?(:schema)
        schema_properties(model).include?(field)
      else
        Bulkrax::ObjectFactory.field_supported?(field:, model:)
      end
    end

    def self.file_sets_for(resource:)
      return [] if resource.blank?
      return [resource] if resource.is_a?(Bulkrax.file_model_class)

      Hyrax.query_service.custom_queries.find_child_file_sets(resource:)
    end

    def self.find(id)
      Hyrax.query_service.find_by(id:)
    rescue Hyrax::ObjectNotFoundError => e
      raise ObjectFactoryInterface::ObjectNotFoundError, e.message
    end

    def self.find_or_create_default_admin_set
      Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    end

    def self.solr_name(field_name)
      raise NotImplementedError, "#{self}.#{__method__}" unless defined?(Hyrax)
      Hyrax.config.index_field_mapper.solr_name(field_name)
    end

    def self.publish(event:, **kwargs)
      Hyrax.publisher.publish(event, **kwargs)
    end

    def self.query(q, **kwargs)
      raise NotImplementedError, "#{self}.#{__method__}" unless defined?(Hyrax)
      Hyrax::SolrService.query(q, **kwargs)
    end

    def self.save!(resource:, user:)
      if resource.respond_to?(:save!)
        resource.save!
      else
        result = Hyrax.persister.save(resource:)
        raise Valkyrie::Persistence::ObjectNotFoundError unless result
        Hyrax.index_adapter.save(resource: result)
        if result.collection?
          publish('collection.metadata.updated', collection: result, user:)
        else
          publish('object.metadata.updated', object: result, user:)
        end
        resource
      end
    end

    def self.update_index(resources:)
      Array(resources).each do |resource|
        Hyrax.index_adapter.save(resource:)
      end
    end

    def self.update_index_for_file_sets_of(resource:)
      file_sets = Hyrax.query_service.custom_queries.find_child_file_sets(resource:)
      update_index(resources: file_sets)
    end

    # Emory override: fixes gem typo (custom_query -> custom_queries) and
    # uses search_field instead of name_field.
    # rubocop:disable Metrics/ParameterLists
    def self.search_by_property(value:, klass:, field: nil, search_field: nil, **)
      search_field ||= field
      raise "Expected search_field or field got nil" if search_field.blank?
      return if value.blank?

      Hyrax.query_service.custom_queries.find_by_model_and_property_value(model: klass, property: search_field, value:)
    end
    # rubocop:enable Metrics/ParameterLists

    def self.schema_properties(klass)
      @schema_properties_map ||= {}

      klass_key = klass.name
      @schema_properties_map[klass_key] = klass.schema.map { |k| k.name.to_s } unless @schema_properties_map.key?(klass_key)

      @schema_properties_map[klass_key]
    end

    def self.ordered_file_sets_for(object)
      return [] if object.blank?

      Hyrax.custom_queries.find_child_file_sets(resource: object)
    end

    def self.export_properties
      properties = Bulkrax.curation_concerns.map { |work| schema_properties(work) }.flatten.uniq.sort
      properties.reject { |prop| Bulkrax.reserved_properties.include?(prop) }
    end

    def delete(user)
      obj = find
      return false unless obj

      Hyrax.persister.delete(resource: obj)
      Hyrax.index_adapter.delete(resource: obj)
      self.class.publish(event: 'object.deleted', object: obj, user:)
    end

    def run!
      run
      object = find
      return object if object&.persisted?

      raise(ObjectFactoryInterface::RecordInvalid, object)
    end

    private

      def apply_depositor_metadata
        return if @object.depositor.present?

        @object.depositor = @user.email
        object = Hyrax.persister.save(resource: @object)
        self.class.publish(event: "object.metadata.updated", object:, user: @user)
        object
      end

      def conditionall_apply_depositor_metadata
        nil
      end

      def conditionally_set_reindex_extent
        nil
      end

      def create_file_set(attrs)
        # TODO: Make it work for Valkyrie
      end

      # Emory override: adds preservation event creation after work creation
      def create_work(attrs)
        event_start = DateTime.current
        attrs = HashWithIndifferentAccess.new(attrs)
        perform_transaction_for(object:, attrs:) do
          uploaded_files, file_set_params = prep_fileset_content(attrs)
          transactions["change_set.create_work"]
            .with_step_args(
              'work_resource.add_file_sets' => { uploaded_files:, file_set_params: },
              "change_set.set_user_as_depositor" => { user: @user },
              "work_resource.change_depositor" => { user: @user },
              'work_resource.save_acl' => { permissions_params: [attrs.try('visibility') || 'open'].compact }
            )
        end

        process_work_creation_preservation_events(event_start)
      end

      def prep_fileset_content(attrs)
        thumbnail_url = HashWithIndifferentAccess.new(attributes)['thumbnail_url']
        all_remote_files = merge_thumbnails(remote_files: attrs["remote_files"], thumbnail_url:)
        all_local_files = attributes['file'] || []
        all_files = all_local_files + all_remote_files

        uploaded_local = uploaded_local_files(uploaded_files: attrs[:uploaded_files])
        uploaded_remote = uploaded_remote_files(remote_files: all_remote_files)
        uploaded_files = uploaded_local + uploaded_remote

        file_set_params = file_set_params_for(uploads: uploaded_files, files: all_files)
        [uploaded_files, file_set_params]
      end

      def merge_thumbnails(remote_files:, thumbnail_url:)
        r = remote_files || []
        thumbnail_url.present? ? r + [thumbnail_url] : r
      end

      def file_set_params_for(uploads:, files:)
        additional_attributes = files.map do |f|
          case f
          when String
            {}
          else
            temp = f.reject { |key, _| key.to_s == 'url' || key.to_s == 'file_name' }
            temp['import_url'] = f['url']
            temp
          end
        end

        file_attrs = []
        uploads.each_with_index do |f, index|
          file_attrs << ({ uploaded_file_id: f["id"].to_s, filename: files[index]["file_name"] }).merge(additional_attributes[index])
        end
        file_attrs.compact.uniq
      end

      def create_collection(attrs)
        perform_transaction_for(object:, attrs:) do
          transactions['change_set.create_collection']
            .with_step_args(
              'change_set.set_user_as_depositor' => { user: @user },
              'collection_resource.apply_collection_type_permissions' => { user: @user }
            )
        end
      end

      def find_by_id
        Hyrax.query_service.find_by(id: attributes[:id]) if attributes.key? :id
      end

      def perform_transaction_for(object:, attrs:)
        form = Hyrax::Forms::ResourceForm.for(object).prepopulate!

        form.validate(attrs)

        transaction = yield

        result = transaction.call(form)

        result.value_or do
          msg = result.failure[0].to_s
          msg += " - #{result.failure[1].full_messages.join(',')}" if result.failure[1].respond_to?(:full_messages)
          raise StandardError, msg, result.trace
        end
      end

      def permitted_attributes
        @permitted_attributes ||= (
          base_permitted_attributes + if klass.respond_to?(:schema)
                                        Bulkrax::ValkyrieObjectFactory.schema_properties(klass)
                                      else
                                        klass.properties.keys.map(&:to_sym)
                                      end
        ).uniq
      end

      # Emory override: adds preservation event creation after work update
      def update_work(attrs)
        event_start = DateTime.current
        attrs = HashWithIndifferentAccess.new(attrs)
        perform_transaction_for(object:, attrs:) do
          uploaded_files, file_set_params = prep_fileset_content(attrs)
          transactions["change_set.update_work"]
            .with_step_args(
              'work_resource.add_file_sets' => { uploaded_files:, file_set_params: },
              'work_resource.save_acl' => { permissions_params: [attrs.try('visibility') || 'open'].compact }
            )
        end

        pulled_work = pull_work_for_preservation_events
        create_preservation_event(pulled_work, work_update(event_start:, user_email: @user.email))
      end

      def update_collection(attrs)
        perform_transaction_for(object:, attrs:) do
          transactions['change_set.update_collection']
        end
      end

      def update_file_set(attrs)
        # TODO: Make it work
      end

      def uploaded_local_files(uploaded_files: [])
        Array.wrap(uploaded_files).map do |file_id|
          Hyrax::UploadedFile.find(file_id)
        end
      end

      def uploaded_s3_files(remote_files: [])
        return [] if remote_files.blank?

        s3_bucket_name = ENV.fetch("STAGING_AREA_S3_BUCKET", "comet-staging-area-#{Rails.env}")
        s3_bucket = Rails.application.config.staging_area_s3_connection
                         .directories.get(s3_bucket_name)

        remote_files.map { |r| r["url"] }.map do |key|
          s3_bucket.files.get(key)
        end.compact
      end

      def uploaded_remote_files(remote_files: [])
        remote_files.map do |r|
          file_path = download_file(r["url"])
          next unless file_path

          create_uploaded_file(file_path, r["file_name"])
        end.compact
      end

      def download_file(url)
        require 'open-uri'
        require 'tempfile'

        begin
          file = Tempfile.new
          file.binmode
          file.write(URI.open(url).read)
          file.rewind
          file.path
        rescue => e
          Rails.logger.debug "Failed to download file from #{url}: #{e.message}"
          nil
        end
      end

      def create_uploaded_file(file_path, file_name)
        file = File.open(file_path)
        uploaded_file = Hyrax::UploadedFile.create(file:, user: @user, filename: file_name)
        file.close
        uploaded_file
      rescue => e
        Rails.logger.debug "Failed to create Hyrax::UploadedFile for #{file_name}: #{e.message}"
        nil
      end

      def destroy_existing_files
        existing_files = Hyrax.custom_queries.find_child_file_sets(resource: object)

        existing_files.each do |fs|
          transactions["file_set.destroy"]
            .with_step_args("file_set.remove_from_work" => { user: @user },
                            "file_set.delete" => { user: @user })
            .call(fs)
            .value!
        end

        @object.member_ids = @object.member_ids.reject { |m| existing_files.detect { |f| f.id == m } }
        @object.rendering_ids = []
        @object.representative_id = nil
        @object.thumbnail_id = nil
      end

      def transform_attributes(update: false)
        attrs = super.merge(alternate_ids: [source_identifier_value])
                     .symbolize_keys

        attrs[:title] = [''] if attrs[:title].blank?
        attrs[:creator] = [''] if attrs[:creator].blank?
        attrs
      end

      def pull_work_for_preservation_events
        Hyrax.query_service.custom_queries.find_by_model_and_property_value(
          model:    CurateGenericWorkResource,
          property: 'deduplication_key_tesim',
          value:    attributes['deduplication_key']
        )
      end

      def process_work_creation_preservation_events(event_start)
        pulled_work = pull_work_for_preservation_events
        return unless pulled_work

        create_preservation_event(pulled_work, work_creation(event_start:, user_email: @user.email))
        create_preservation_event(pulled_work, work_policy(event_start:, visibility: pulled_work.visibility, user_email: @user.email))
      end
  end
  # rubocop:enable Metrics/ClassLength
end
