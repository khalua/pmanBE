class Web::Manager::InvitationsController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!
  before_action :set_property

  def index
    @invitations = TenantInvitation
      .joins(:unit)
      .where(units: { property_id: @property.id }, created_by: current_user)
      .includes(:unit, :claimed_by)
      .order(created_at: :desc)
    @units = @property.units.order(:identifier)
  end

  def create
    unit = @property.units.find(params[:invitation][:unit_id])
    invitation = unit.tenant_invitations.build(invitation_params.merge(created_by: current_user))

    if invitation.save
      UserMailer.tenant_invitation(invitation).deliver_later
      redirect_to web_manager_property_invitations_path(@property), notice: "Invitation created and email sent to #{invitation.tenant_email}. Code: #{invitation.code}"
    else
      @invitations = TenantInvitation
        .joins(:unit)
        .where(units: { property_id: @property.id }, created_by: current_user)
        .includes(:unit, :claimed_by)
        .order(created_at: :desc)
      @units = @property.units.order(:identifier)
      flash.now[:alert] = invitation.errors.full_messages.join(", ")
      render :index, status: :unprocessable_entity
    end
  end

  def revoke
    invitation = TenantInvitation
      .joins(:unit)
      .where(units: { property_id: @property.id }, created_by: current_user)
      .find(params[:id])

    invitation.update!(active: false)
    redirect_to web_manager_property_invitations_path(@property), notice: "Invitation revoked."
  end

  private

  def set_property
    @property = current_user.properties.find(params[:property_id])
  end

  def invitation_params
    params.require(:invitation).permit(:tenant_name, :tenant_email)
  end

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
