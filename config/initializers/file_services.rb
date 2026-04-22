# frozen_string_literal: true
# [Hyrax-override-v5.2.0] Configures Hydra::Derivatives to use Valkyrie-compatible
# file services for derivative persistence and source file retrieval.
#
# Without this, ValkyrieCreateDerivativesJob (triggered via the FileListener on
# 'file.characterized') would fall back to AF-based persistence, which fails for
# Valkyrie-born file sets stored via Valkyrie::StorageAdapter.

if Hyrax.config.valkyrie_transition?
  ActiveSupport::Reloader.to_prepare do
    Hydra::Derivatives.config.output_file_service = Hyrax::ValkyriePersistDerivatives
    Hydra::Derivatives.config.source_file_service = Hyrax::LocalFileService
  end
end
