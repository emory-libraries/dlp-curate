require_relative '../prepends/hyrax_record_importer_prepends'
require_relative '../prepends/custom_access_rights'
require_relative '../prepends/custom_visibility'

Zizia::HyraxRecordImporter.prepend(HyraxRecordImporterPrepends)
Hydra::AccessControls::AccessRight.prepend(CustomAccessRights)
Hydra::AccessControls::Visibility.prepend(CustomVisibility)
