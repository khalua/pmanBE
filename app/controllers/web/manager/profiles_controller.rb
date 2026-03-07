class Web::Manager::ProfilesController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!

  def edit
  end

  def update
    if password_change_requested? && !current_user.authenticate(params[:current_password].to_s)
      flash.now[:alert] = "Current password is incorrect."
      render :edit, status: :unprocessable_entity
      return
    end

    if current_user.update(profile_params)
      redirect_to edit_web_manager_profile_path, notice: "Profile updated successfully."
    else
      flash.now[:alert] = current_user.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_change_requested?
    params[:password].present?
  end

  def profile_params
    if password_change_requested?
      params.require(:user).permit(:name, :cell_phone, :email, :password, :password_confirmation)
    else
      params.require(:user).permit(:name, :cell_phone, :email)
    end
  end

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
