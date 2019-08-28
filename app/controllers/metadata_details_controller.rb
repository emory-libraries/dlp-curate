class MetadataDetailsController < ApplicationController
  def show
    @details = ::MetadataDetails.instance.details(work_attributes:
                                                CurateGenericWorkAttributes.instance)
  end

  def csv
    @csv = ::MetadataDetails.instance.to_csv(work_attributes:
                                              CurateGenericWorkAttributes.instance)
    send_data @csv, type: 'text/csv', filename: "metadata-profile-#{Date.current}.csv"
  end
end
