# Generated via
#  `rails generate hyrax:work CurateGenericWork`
module Hyrax
  module Actors
    class CurateGenericWorkActor < Hyrax::Actors::BaseActor
      def apply_save_data_to_curation_concern(env)
        # Insert break here to see what metadata is about to be saved on the object
        # byebug
        super
      end
    end
  end
end
