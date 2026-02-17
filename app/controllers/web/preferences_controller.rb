class Web::PreferencesController < WebController
  before_action :authenticate_user!

  def show
  end

  def update
    if params[:google_auth_enabled] == "1" && current_user.gmail_account?
      current_user.update!(google_auth_enabled: true)
      redirect_to web_preferences_path, notice: "Google login enabled."
    else
      current_user.update!(google_auth_enabled: false)
      redirect_to web_preferences_path, notice: "Google login disabled."
    end
  end
end
