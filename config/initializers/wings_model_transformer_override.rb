# frozen_string_literal: true
Rails.application.config.after_initialize do
  Wings::ModelTransformer.class_eval do
    ##
    # Builds a `Valkyrie::Resource` equivalent to the `pcdm_object`
    #
    # @return [::Valkyrie::Resource] a resource mirroring `pcdm_object`
    # rubocop:disable Metrics/AbcSize
    def build
      klass = cache.fetch(pcdm_object.class) do
        Wings::OrmConverter.to_valkyrie_resource_class(klass: pcdm_object.class)
      end
      mint_id unless pcdm_object.id

      attrs = attributes.tap { |hash| hash[:new_record] = pcdm_object.new_record? }

      klass.new(**attrs).tap do |resource|
        resource.lease = pcdm_object.lease&.valkyrie_resource if pcdm_object.respond_to?(:lease) && pcdm_object.lease
        resource.embargo = pcdm_object.embargo&.valkyrie_resource if pcdm_object.respond_to?(:embargo) && pcdm_object.embargo
        resource.internal_resource = klass.internal_resource
        resource.emory_persistent_id = pcdm_object.id.to_s if pcdm_object.id && resource.respond_to?(:emory_persistent_id)
        check_size(resource)
        check_pcdm_use(resource)
        ensure_current_permissions(resource)
      end
    end
  end
end
