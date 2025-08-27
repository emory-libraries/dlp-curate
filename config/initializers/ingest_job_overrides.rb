# frozen_string_literal: true

# [Hyrax-overwrite-v3.4.2] adds in retry_on logic to quiet loud, repetive errors.
IngestJob.class_eval do
  retry_on(Ldp::HttpError) do |_job, error|
    raise Ldp::HttpError, error.message if error.message.include?('org.modeshape.jcr.value.binary.BinaryStoreException')
    Rails.logger.error(error.message)
  end
end
