# frozen_string_literal: true

# These classes branch on Hyrax.config.valkyrie_transition? in their class bodies
# (e.g. picking curation_concern_type or calling Hyrax::ValkyrieLazyMigration.migrating).
# Load them before any spec stubs valkyrie_transition?, so a stubbed value can't be
# baked in by whichever spec happens to autoload them first.
RSpec.configure do |config|
  config.before(:suite) do
    [Hyrax::CurateGenericWorksController, CurateGenericWorkResource, FileSetResource,
     CollectionResource, AdminSetResource].each(&:name)
  end
end
