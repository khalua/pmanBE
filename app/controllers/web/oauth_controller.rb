class Web::OauthController < WebController
  def google
    auth = request.env["omniauth.auth"]

    user = User.find_by(provider: auth.provider, uid: auth.uid)
    user ||= User.find_by("LOWER(email) = ?", auth.info.email&.downcase)

    unless user
      redirect_to login_path, alert: "No account found for #{auth.info.email}. Ask your property manager for an invitation."
      return
    end

    unless user.google_auth_enabled?
      redirect_to login_path, alert: "Google login is not enabled for your account. Enable it in Preferences, or log in with your password."
      return
    end

    # Link Google provider/uid if not already linked
    user.update!(provider: auth.provider, uid: auth.uid) if user.provider.blank?

    session[:user_id] = user.id
    if user.super_admin?
      redirect_to web_admin_dashboard_path, notice: "Logged in with Google."
    elsif user.property_manager?
      redirect_to web_manager_dashboard_path, notice: "Logged in with Google."
    else
      redirect_to web_tenant_dashboard_path, notice: "Logged in with Google."
    end
  end

  def failure
    redirect_to login_path, alert: "Authentication failed: #{params[:message]}"
  end
end
