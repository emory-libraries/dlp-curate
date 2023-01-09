# frozen_string_literal: true
require_relative './export_assistive_methods'
require_relative './ingest_assistive_methods'

module OverrideAssistiveMethods
  include ExportAssistiveMethods
  include IngestAssistiveMethods
end
