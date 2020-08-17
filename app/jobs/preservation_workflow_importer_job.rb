# frozen_string_literal: true

class PreservationWorkflowImporterJob < Hyrax::ApplicationJob
  def perform(file)
    PreservationWorkflowImporter.import(file)
  end
end
