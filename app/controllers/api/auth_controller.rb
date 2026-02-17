class Api::AuthController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :register, :login ]

  def register
    if register_params[:role] == "property_manager"
      register_property_manager
    else
      register_tenant
    end
  end

  def login
    user = User.find_by(email: params[:email]&.downcase)
    if user&.authenticate(params[:password])
      if user.tenant? && !user.active?
        render json: { error: "Your account has been deactivated. Contact your property manager." }, status: :forbidden
        return
      end

      if user.tenant? && !user.phone_verified?
        token = JwtService.encode(user_id: user.id)
        render json: { token: token, user: user_json(user), phone_verification_required: true }
        return
      end

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

  def register_tenant
    invitation = TenantInvitation.available.find_by(code: params[:invite_code])

    if invitation.nil?
      render json: { error: "Invalid or expired invitation code" }, status: :unprocessable_entity
      return
    end

    if params[:email]&.downcase != invitation.tenant_email.downcase
      render json: { error: "Email does not match the invitation" }, status: :unprocessable_entity
      return
    end

    user = User.new(register_params.merge(role: :tenant, unit_id: invitation.unit_id, move_in_date: Date.current))
    if user.save
      invitation.update!(claimed_by: user)
      token = JwtService.encode(user_id: user.id)
      render json: { token: token, user: user_json(user), phone_verification_required: true }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def register_property_manager
    user = User.new(register_params.merge(role: :property_manager))
    if user.save
      token = JwtService.encode(user_id: user.id)
      render json: { token: token, user: user_json(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def register_params
    params.permit(:email, :password, :name, :phone, :mobile_phone, :address, :role)
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      address: user.address,
      role: user.role,
      phone_verified: user.phone_verified
    }
  end
end
