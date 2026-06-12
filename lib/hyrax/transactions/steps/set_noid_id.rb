# frozen_string_literal: true

require 'noid-rails'

module Hyrax
  module Transactions
    module Steps
      ##
      # A step that mints a NOID and stores it in the change set's
      # +alternate_ids+. During the Freyja/Wings phase the AF model's
      # +assign_id+ already sets the resource +id+ to the NOID, so this
      # step provides a redundant lookup path. Post-Wings (pure Valkyrie),
      # this becomes the primary NOID assignment mechanism.
      class SetNoidId
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::ChangeSet] change_set
        def call(change_set)
          return Success(change_set) unless change_set.respond_to?(:alternate_ids=)
          return Success(change_set) if noid_already_assigned?(change_set)

          noid = mint_noid
          existing = Array(change_set.alternate_ids)
          change_set.alternate_ids = existing + [Valkyrie::ID.new(noid)]
          Hyrax.persister.save(resource: change_set)
          Success(change_set)
        end

        private

          def mint_noid
            "#{::Noid::Rails::Service.new.mint}#{Rails.configuration.x.curate_template}"
          end

          def noid_already_assigned?(change_set)
            suffix = Rails.configuration.x.curate_template
            id = change_set.id.to_s
            return true if id.present? && id.end_with?(suffix)

            Array(change_set.alternate_ids).any? { |aid| aid.to_s.end_with?(suffix) }
          end
      end
    end
  end
end
