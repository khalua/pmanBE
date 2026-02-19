class Web::RegistrationsController < WebController
  before_action :load_invitation

  def new
    unless @invitation || @manager_invitation
      redirect_to login_path, alert: "You need an invitation link to register. Contact your property manager."
      return
    end
  end

  def create
    unless @invitation || @manager_invitation
      redirect_to login_path, alert: "You need an invitation link to register."
      return
    end

    if @manager_invitation
      create_manager_account
    else
      create_tenant_account
    end
  end

  private

  def load_invitation
    if params[:invite_code].present?
      @invitation = TenantInvitation.available.find_by(code: params[:invite_code])
    elsif params[:manager_invite_code].present?
      @manager_invitation = ManagerInvitation.available.find_by(code: params[:manager_invite_code])
    end
  end

  def create_tenant_account
    user = User.new(
      name: params[:name].presence || @invitation.tenant_name,
      email: @invitation.tenant_email,
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      mobile_phone: params[:mobile_phone],
      role: :tenant,
      unit_id: @invitation.unit_id,
      move_in_date: Date.current
    )

    if user.save
      @invitation.update!(claimed_by: user, active: false)
      session[:user_id] = user.id
      redirect_to web_tenant_dashboard_path, notice: "Welcome! Your account has been created."
    else
      @errors = user.errors
      flash.now[:alert] = user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def create_manager_account
    user = User.new(
      name: params[:name].presence || @manager_invitation.manager_name,
      email: @manager_invitation.manager_email,
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      mobile_phone: params[:mobile_phone],
      role: :property_manager
    )

    if user.save
      @manager_invitation.update!(claimed_by: user, active: false)
      session[:user_id] = user.id
      redirect_to web_manager_dashboard_path, notice: "Welcome! Your property manager account has been created."
    else
      @errors = user.errors
      flash.now[:alert] = user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end
end
