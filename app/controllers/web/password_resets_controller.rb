class Web::PasswordResetsController < WebController
  def new
  end

  def create
    user = User.find_by("LOWER(email) = ?", params[:email]&.downcase)

    if user&.google_auth_enabled? && user&.provider.present?
      redirect_to login_path, notice: "That account uses Google login. Click \"Continue with Google\" to sign in."
      return
    end

    if user
      token = SecureRandom.urlsafe_base64(32)
      user.update!(password_reset_token: token, password_reset_sent_at: Time.current)
      UserMailer.password_reset(user).deliver_later
    end

    redirect_to login_path, notice: "If that email exists, you'll receive reset instructions."
  end

  def edit
    @user = User.find_by(password_reset_token: params[:token])

    if @user.nil? || @user.password_reset_sent_at < 2.hours.ago
      redirect_to forgot_password_path, alert: "Invalid or expired reset link."
    end
  end

  def update
    @user = User.find_by(password_reset_token: params[:token])

    if @user.nil? || @user.password_reset_sent_at < 2.hours.ago
      redirect_to forgot_password_path, alert: "Invalid or expired reset link."
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.update!(password_reset_token: nil, password_reset_sent_at: nil)
      redirect_to login_path, notice: "Password updated. Please log in."
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end
end
