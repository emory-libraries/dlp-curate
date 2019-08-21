class MetadataDetailsController < ApplicationController
  def show
    @details = ::MetadataDetails.instance.details(work_attributes:
                                                CurateGenericWorkAttributes.instance)
  end
end
