class Web::Tenant::ProfilesController < WebController
  before_action :authenticate_user!
  before_action :require_tenant!

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to web_tenant_dashboard_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:email, :mobile_phone, :home_phone)
  end

  def require_tenant!
    redirect_to root_path, alert: "Not authorized." unless current_user&.tenant?
  end
end
