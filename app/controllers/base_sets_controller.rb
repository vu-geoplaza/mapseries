class BaseSetsController < ApplicationController
  def index
    @base_series=BaseSeries.find(params[:base_series_id])
    @base_sets=@base_series.base_sets
    @periods=get_periods
    # get first and last pubyear
    logger.debug @periods
    respond_to do |format|
      format.html

    end
  end

  def get_periods
    periods=[]
    @base_sets.each do |set|
      first=set.sheets.order(:pubdate).first
      last=set.sheets.order(:pubdate).last
      logger.debug first.pubdate.year
      periods[set.id]=[first.pubdate.year, last.pubdate.year]
    end
    periods
  end

end