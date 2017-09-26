class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nickname, :image])
    devise_parameter_sanitizer.permit(:account_update, keys: [:nickname, :image])
  end

  private

  def check_if_user_is_admin
    if !current_user.is_admin?
      flash[:alert] = "You don\'t have permission to do that"
      redirect_to root_url
    end
  end
end
