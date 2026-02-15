class Web::Admin::UsersController < WebController
  before_action :authenticate_user!
  before_action :require_super_admin!

  def index
    @users = User.order(created_at: :desc)
  end

  def destroy
    user = User.find(params[:id])

    if user == current_user
      redirect_to web_admin_users_path, alert: "Cannot delete yourself."
      return
    end

    user.destroy!
    redirect_to web_admin_users_path, notice: "User deleted."
  end

  private

  def require_super_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user&.super_admin?
  end
end
