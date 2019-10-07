module Zizia
  class StartCsvImportJob < ApplicationJob
    queue_as :default

    def perform(csv_import_id)
      csv_import = CsvImport.find csv_import_id
      importer = ModularImporter.new(csv_import)
      importer.extend(ModularImporterDetailsDecorator)
      importer.extend(ModularImporterLoggingDecorator)
      importer.import
    end
  end
end
