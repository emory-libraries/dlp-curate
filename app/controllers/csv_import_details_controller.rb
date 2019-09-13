class CsvImportDetailsController < ApplicationController
  def index
    @csv_import_details = Zizia::CsvImportDetail.all
  end

  def show
    @csv_import_detail = Zizia::CsvImportDetail.find(csv_import_detail_params["id"])
  end

  private

    def csv_import_detail_params
      params.permit(:id)
    end
end
