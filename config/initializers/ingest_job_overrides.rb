# frozen_string_literal: true
# [Hyrax-override-hyrax-v5.2.0] adds in retry_on logic for Fedora/LDP errors.
#
# Re-raises fatal errors (BinaryStoreException, NullPointerException) so they
# surface in error tracking. Transient LDP errors are retried with exponential
# backoff and then logged if all attempts are exhausted.

FATAL_LDP_PATTERNS = [
  'org.modeshape.jcr.value.binary.BinaryStoreException',
  'java.lang.NullPointerException'
].freeze

Rails.application.config.to_prepare do
  IngestJob.class_eval do
    retry_on(Ldp::HttpError, wait: :polynomially_longer, attempts: 5) do |_job, error|
      raise Ldp::HttpError, error.message if FATAL_LDP_PATTERNS.any? { |pattern| error.message.include?(pattern) }
      Rails.logger.error("[IngestJob] LDP error after all retries exhausted: #{error.message}")
    end
  end
end
