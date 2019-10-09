# frozen_string_literal: true

module Zizia
  class StartCsvImportJob < ApplicationJob
    queue_as :default

    def perform(csv_import_id)
      csv_import = CsvImport.find csv_import_id
      importer = ModularImporter.new(csv_import)
      importer.extend(ModularImporterDetailsDecorator)
      importer.extend(ModularImporterLoggingDecorator)
      importer.extend(ModularImporterUpdateDecorator)
      importer.import
    end
  end
end
