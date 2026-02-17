class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @reset_url = reset_password_url(token: user.password_reset_token)
    mail(to: user.email, subject: "Reset your Prompt password")
  end

  def tenant_invitation(invitation)
    @invitation = invitation
    @register_url = register_url(invite_code: invitation.code)
    @property = invitation.unit.property
    @manager = invitation.created_by
    mail(to: invitation.tenant_email, subject: "You've been invited to join #{@property.name.presence || @property.address} on Prompt")
  end
end
