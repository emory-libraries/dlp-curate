ActiveSupport::Reloader.to_prepare do
  Hydra::Derivatives.source_file_service = Hyrax::LocalFileService
  Hydra::Derivatives.output_file_service = Hyrax::PersistDerivatives
  Hydra::Derivatives::FullTextExtract.output_file_service = Hyrax::PersistDirectlyContainedOutputFileService
end
