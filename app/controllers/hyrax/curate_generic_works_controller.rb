# Generated via
#  `rails generate hyrax:work CurateGenericWork`
module Hyrax
  # Generated controller for CurateGenericWork
  class CurateGenericWorksController < ApplicationController
    # Adds Hyrax behaviors to the controller.
    include Hyrax::WorksControllerBehavior
    include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::CurateGenericWork

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::CurateGenericWorkPresenter
  end
end
