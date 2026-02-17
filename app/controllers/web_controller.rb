class WebController < ApplicationController
  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def user_dashboard_path
    return root_path unless current_user

    case current_user.role
    when "super_admin"
      web_admin_dashboard_path
    when "property_manager"
      web_manager_dashboard_path
    when "tenant"
      web_tenant_dashboard_path
    else
      root_path
    end
  end
  helper_method :user_dashboard_path

  def authenticate_user!
    unless current_user
      redirect_to login_path, alert: "Please log in to continue."
    end
  end
end
