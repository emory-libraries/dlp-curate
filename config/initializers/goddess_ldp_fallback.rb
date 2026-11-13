# frozen_string_literal: true

# Goddess query strategies only rescue Valkyrie::Persistence::ObjectNotFoundError
# when iterating over inner services.  During lazy migration, the Frigg (Fedora 6)
# service is tried first.  For AF-origin objects that only exist in Fedora 4, the
# Frigg service can raise several LDP/Fedora errors:
#
#   - Ldp::BadRequest — Fedora 6.5+ rejects IDs with unsupported characters
#     (e.g. slashes in legacy AF IDs like "admin_set/default").
#   - Ldp::HttpError — Fedora 6 returns 404/500 for objects that don't exist there.
#   - Ldp::Gone — Fedora 6 returns 410 for tombstoned objects.
#   - Faraday::Error (ConnectionFailed, TimeoutError, etc.) — Fedora 6 is temporarily
#     unreachable or slow.
#
# Without rescuing these errors the composite query short-circuits and Wings never
# gets a chance to resolve the object from ActiveFedora / Fedora 4.
#
# This reopens the private MethodMissingMachinations module and overrides the three
# strategy methods so they rescue all these error types, letting the next service in
# the chain attempt the lookup.
GODDESS_FALLBACK_ERRORS = [
  Valkyrie::Persistence::ObjectNotFoundError,
  Ldp::BadRequest,
  Ldp::HttpError,
  Ldp::Gone,
  Faraday::Error
].freeze

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
        rescue *GODDESS_FALLBACK_ERRORS => e
          Rails.logger.debug { "[Goddess] #{service.class}##{method_name} fell through: #{e.class}" }
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
        rescue *GODDESS_FALLBACK_ERRORS => e
          Rails.logger.debug { "[Goddess] #{service.class}##{method_name} fell through: #{e.class}" }
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
        rescue *GODDESS_FALLBACK_ERRORS => e
          Rails.logger.debug { "[Goddess] #{service.class}##{method_name} fell through: #{e.class}" }
          next
        end

        result_sets.max
      end
  end
end
