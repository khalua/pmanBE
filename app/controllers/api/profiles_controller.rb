class Api::ProfilesController < Api::BaseController
  def show
    render json: { user: user_json(current_user) }
  end

  def update
    if password_change_requested?
      return render json: { error: "Current password is required to change your password" }, status: :unprocessable_entity unless params[:current_password].present?
      return render json: { error: "Current password is incorrect" }, status: :unprocessable_entity unless current_user.authenticate(params[:current_password])
    end

    if current_user.update(profile_params)
      render json: { user: user_json(current_user) }
    else
      render json: { error: current_user.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def password_change_requested?
    params[:password].present?
  end

  def profile_params
    permitted = params.permit(:name, :cell_phone, :email)
    if password_change_requested?
      permitted = params.permit(:name, :cell_phone, :email, :password, :password_confirmation)
    end
    permitted
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      cell_phone: user.cell_phone,
      address: user.address,
      role: user.role,
      phone_verified: user.phone_verified
    }
  end
end
