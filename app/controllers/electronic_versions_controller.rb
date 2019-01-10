class ElectronicVersionsController < ApplicationController
  def index
    unless params[:copy_id].nil?
      @copy=Copy.find(params[:copy_id])
      @electronic_versions = @copy.electronic_versions
      @sheet=@copy.sheet
    end
  end
end