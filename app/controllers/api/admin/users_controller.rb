class Api::Admin::UsersController < Api::Admin::BaseController
  def index
    users = User.select(:id, :email, :name, :role, :created_at).order(:id)
    render json: users
  end

  def destroy
    user = User.find(params[:id])

    if user == current_user
      render json: { error: "Cannot delete yourself" }, status: :unprocessable_entity
      return
    end

    user.destroy!
    render json: { message: "User deleted" }
  end
end
