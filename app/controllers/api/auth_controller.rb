class Api::AuthController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :register, :login ]

  def register
    user = User.new(register_params)
    if user.save
      token = JwtService.encode(user_id: user.id)
      render json: { token: token, user: user_json(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email]&.downcase)
    if user&.authenticate(params[:password])
      token = JwtService.encode(user_id: user.id)
      render json: { token: token, user: user_json(user) }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def me
    render json: { user: user_json(current_user) }
  end

  private

  def register_params
    params.permit(:email, :password, :name, :phone, :address, :role)
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      address: user.address,
      role: user.role
    }
  end
end
