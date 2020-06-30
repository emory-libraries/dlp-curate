# frozen_string_literal: true
class EventDetailsController < ApplicationController
  skip_before_action :authenticate_user!

  def event_details
    respond_to do |wants|
      wants.html { @presenter = event_details_presenter }
    end
  end

  private

    def document
      SolrDocument.find(params['id'])
    end

    def ability
      EventDetailsAbility.new
    end

    def event_details_presenter
      Hyrax::CurateGenericWorkPresenter.new(document, ability)
    end
end
