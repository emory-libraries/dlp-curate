# frozen_string_literal: true

require 'noid-rails'

module Hyrax
  module Transactions
    module Steps
      ##
      # A step that mints a NOID and stores it as a plain string in the
      # change set's +emory_persistent_id+. This avoids using +alternate_ids+,
      # which Frigg's persister materializes as separate Fedora objects.
      class SetNoidId
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::ChangeSet] change_set
        def call(change_set)
          return Failure[:no_emory_persistent_id, change_set] unless
            change_set.respond_to?(:emory_persistent_id=)
          return Success(change_set) if
            change_set.emory_persistent_id.present?

          change_set.emory_persistent_id = mint_noid
          Hyrax.persister.save(resource: change_set)
          Success(change_set)
        end

        private

          def mint_noid
            "#{::Noid::Rails::Service.new.mint}#{Rails.configuration.x.curate_template}"
          end
      end
    end
  end
end
