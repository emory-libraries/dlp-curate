# frozen_string_literal: true

# Goddess query strategies only rescue Valkyrie::Persistence::ObjectNotFoundError
# when iterating over inner services.  Fedora 6.5+ raises Ldp::BadRequest for IDs
# that contain characters it does not support (e.g. slashes in legacy AF IDs like
# "admin_set/default").  Without this patch the error short-circuits the composite
# query and Wings never gets a chance to resolve the object from ActiveFedora.
#
# This reopens the private MethodMissingMachinations module and overrides the three
# strategy methods so they also rescue Ldp::BadRequest, letting the next service in
# the chain attempt the lookup.
if defined?(Goddess::Query::MethodMissingMachinations)
  Goddess::Query::MethodMissingMachinations.module_eval do
    private

      def query_strategy_for_find_single(method_name, *args, **opts, &block)
        opts[:model] = setup_model(opts[:model]) if opts[:model]
        result = nil
        services.each do |service|
          next unless service.respond_to?(method_name)
          result = service.send(method_name, *args, **opts, &block)
          return result if result.present?
        rescue Valkyrie::Persistence::ObjectNotFoundError, Ldp::BadRequest
          next
        end

        return result unless result.nil?
        raise Valkyrie::Persistence::ObjectNotFoundError
      end

      def query_strategy_for_find_multiple(method_name, *args, **opts, &block)
        opts[:model] = setup_model(opts[:model]) if opts[:model]
        result_sets = []
        services.each do |service|
          next unless service.respond_to?(method_name)
          result = service.send(method_name, *args, **opts, &block)
          result_sets << result.to_a if result.present? && result.respond_to?(:any?) && result.any?
        rescue Valkyrie::Persistence::ObjectNotFoundError, Ldp::BadRequest
          next
        end

        total_results(result_sets)
      end

      def query_strategy_for_count_multiple(method_name, *args, **opts, &block)
        opts[:model] = setup_model(opts[:model]) if opts[:model]
        result_sets = []
        services.each do |service|
          result = service.send(method_name, *args, **opts, &block)
          result_sets << result if result.present?
        rescue Valkyrie::Persistence::ObjectNotFoundError, Ldp::BadRequest
          next
        end

        result_sets.max
      end
  end
end
