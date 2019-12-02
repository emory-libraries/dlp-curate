class MetadataDetailsController < ApplicationController
  def show
    @details = ::MetadataDetails.instance.details(work_attributes:
                                                    CurateGenericWorkAttributes.instance)
    respond_to do |format|
      format.html
      format.json { render json: @details.to_json }
      format.any { redirect_to action: :show }
    end
  end

  def profile
    @csv = ::MetadataDetails.instance.to_csv(work_attributes:
                                              CurateGenericWorkAttributes.instance)
    send_data @csv, type: 'text/csv', filename: "metadata-profile-#{Date.current}.csv"
  end
end
