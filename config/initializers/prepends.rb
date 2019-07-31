require_relative '../prepends/hyrax_record_importer_prepends'
require_relative '../prepends/csv_manifest_validator_prepends'

Zizia::HyraxRecordImporter.prepend(HyraxRecordImporterPrepends)
Zizia::CsvManifestValidator.prepend(CsvManifestValidatorPrepends)
