class BaseSeriesController < ApplicationController
  def index
    @base_series = BaseSeries.all
    @periods=get_periods
  end

  def show

  end

  def get_periods
    periods={}
    @base_series.each do |s|
      first=s.sheets.order(:pubdate).first
      last=s.sheets.order(:pubdate).last
      logger.debug first.pubdate.year
      periods[s.abbr]=[first.pubdate.year, last.pubdate.year]
    end
    periods
  end
end
