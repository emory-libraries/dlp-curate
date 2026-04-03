# frozen_string_literal: true
# NOTE: Please remove this once we start testing Valkyrized objects. The models will automatically revert to
#   the Valkyrized classes.

Rails.application.config.to_prepare do
  Hydra::Derivatives.source_file_service = Hyrax::LocalFileService
  Hydra::Derivatives.output_file_service = Hyrax::PersistDerivatives
  Hydra::Derivatives::FullTextExtract.output_file_service = Hyrax::PersistDirectlyContainedOutputFileService
end
