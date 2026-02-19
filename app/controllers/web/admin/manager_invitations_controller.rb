class Web::Admin::ManagerInvitationsController < WebController
  before_action :authenticate_user!
  before_action :require_super_admin!

  def index
    @invitations = ManagerInvitation.includes(:created_by, :claimed_by).order(created_at: :desc)
  end

  def create
    invitation = ManagerInvitation.new(invitation_params.merge(created_by: current_user))

    if invitation.save
      UserMailer.manager_invitation(invitation).deliver_later
      redirect_to web_admin_manager_invitations_path,
        notice: "Invitation created and email sent to #{invitation.manager_email}. Code: #{invitation.code}"
    else
      @invitations = ManagerInvitation.includes(:created_by, :claimed_by).order(created_at: :desc)
      flash.now[:alert] = invitation.errors.full_messages.join(", ")
      render :index, status: :unprocessable_entity
    end
  end

  def revoke
    invitation = ManagerInvitation.find(params[:id])
    invitation.update!(active: false)
    redirect_to web_admin_manager_invitations_path, notice: "Invitation revoked."
  end

  private

  def invitation_params
    params.require(:manager_invitation).permit(:manager_name, :manager_email)
  end

  def require_super_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user&.super_admin?
  end
end
