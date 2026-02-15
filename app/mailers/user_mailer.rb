class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @reset_url = reset_password_url(token: user.password_reset_token)
    mail(to: user.email, subject: "Reset your PropMan password")
  end
end
