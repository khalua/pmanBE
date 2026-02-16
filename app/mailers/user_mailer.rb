class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @reset_url = reset_password_url(token: user.password_reset_token)
    mail(to: user.email, subject: "Reset your Prompt password")
  end

  def unassigned_tenant_login(tenant)
    @tenant = tenant
    admin_emails = User.super_admin.pluck(:email)
    return if admin_emails.empty?

    mail(
      to: admin_emails,
      subject: "Alert: Unassigned tenant attempted login - #{tenant.name}"
    )
  end
end
