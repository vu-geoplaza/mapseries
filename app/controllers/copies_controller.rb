class CopiesController < ApplicationController
  def index
    unless params[:sheet_id].nil?
      @sheet = Sheet.find(params[:sheet_id])
      @base_series = @sheet.base_set.base_series
      @copies = @sheet.copies
    end
    unless params[:base_series_id].nil?
      @base_series = BaseSeries.find(params[:base_series_id])
      if !params[:library_id].nil?
        @library=Library.find(params[:library_id])
        @copies = @library.copies
      elsif !params[:shelfmark_id].nil?
        @shelfmark=Shelfmark.find(params[:shelfmark_id])
        @library=@shelfmark.library
        @copies = @shelfmark.copies
      else
        @copies = @base_series.copies
      end
    end
  end
  # should have an new, edit, destroy and move (to a different sheet) option
end