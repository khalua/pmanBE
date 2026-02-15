class Web::OauthController < WebController
  def google
    auth = request.env["omniauth.auth"]
    user = User.find_by(provider: auth.provider, uid: auth.uid)

    unless user
      user = User.find_by("LOWER(email) = ?", auth.info.email&.downcase)
      if user
        user.update!(provider: auth.provider, uid: auth.uid)
      else
        user = User.create!(
          name: auth.info.name,
          email: auth.info.email,
          provider: auth.provider,
          uid: auth.uid,
          password: SecureRandom.hex(16)
        )
      end
    end

    session[:user_id] = user.id
    if user.super_admin?
      redirect_to web_admin_dashboard_path, notice: "Logged in with Google."
    else
      redirect_to root_path, notice: "Logged in with Google."
    end
  end

  def failure
    redirect_to login_path, alert: "Authentication failed: #{params[:message]}"
  end
end
