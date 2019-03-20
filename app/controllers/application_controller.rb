class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  protect_from_forgery with: :exception
  include Pundit
  after_action :verify_authorized, except: :index, unless: :devise_controller?
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
