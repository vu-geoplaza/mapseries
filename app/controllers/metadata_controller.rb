class MetadataController < ApplicationController
  def index
    if params[:base_series_id]
      base_series = BaseSeries.find(params[:base_series_id])
      @base_sheet = base_series.base_sheets.first
      @base_series = base_series
      @sheets = base_series.sheets.order(:pubdate)
      metadata=base_series.metadata.order(:nummer)

    end
  end
end