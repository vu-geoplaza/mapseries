class BaseSheetsController < ApplicationController
  def index
    base_series = BaseSeries.find(params[:base_series_id])
    @base_series = base_series
    @base_sheets = base_series.base_sheets
  end
end
