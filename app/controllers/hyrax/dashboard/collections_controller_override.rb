# frozen_string_literal: true
module Hyrax
  module Dashboard
    module CollectionsControllerOverride
      def self.prepended(_base)
        Hyrax::CollectionsController.presenter_class = Hyrax::CurateCollectionPresenter
      end
    end
  end
end
