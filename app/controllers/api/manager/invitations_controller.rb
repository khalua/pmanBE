class Api::Manager::InvitationsController < Api::Manager::BaseController
  before_action :set_property, only: [ :index, :create ]
  before_action :set_invitation, only: [ :destroy ]

  def index
    scope = TenantInvitation.joins(:unit).where(units: { property_id: @property.id })
    scope = scope.where(created_by: current_user) unless current_user.super_admin?
    invitations = scope.includes(:unit, :claimed_by).order(created_at: :desc)

    render json: invitations.map { |inv| invitation_json(inv) }
  end

  def create
    unit = @property.units.find(params[:unit_id])
    invitation = unit.tenant_invitations.build(invitation_params.merge(created_by: current_user))

    if invitation.save
      UserMailer.tenant_invitation(invitation).deliver_later
      render json: invitation_json(invitation), status: :created
    else
      render json: { errors: invitation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @invitation.update!(active: false)
    render json: { message: "Invitation revoked" }
  end

  private

  def set_property
    @property = if current_user.super_admin?
      Property.find(params[:property_id])
    else
      current_user.properties.find(params[:property_id])
    end
  end

  def set_invitation
    @invitation = if current_user.super_admin?
      TenantInvitation.find(params[:id])
    else
      TenantInvitation.where(created_by: current_user).find(params[:id])
    end
  end

  def invitation_params
    params.require(:invitation).permit(:tenant_name, :tenant_email)
  end

  def invitation_json(inv)
    {
      id: inv.id,
      code: inv.code,
      tenant_name: inv.tenant_name,
      tenant_email: inv.tenant_email,
      unit: { id: inv.unit.id, identifier: inv.unit.identifier },
      active: inv.active,
      claimed: inv.claimed?,
      claimed_by: inv.claimed_by ? { id: inv.claimed_by.id, name: inv.claimed_by.name } : nil,
      expires_at: inv.expires_at,
      created_at: inv.created_at
    }
  end
end
