class VendorNotificationMailer < ApplicationMailer
  default from: "SMS Simulator <noreply@yerko.com>"

  def sms_simulation(vendor_name, sms_body)
    @sms_body = sms_body
    mail(
      to: "tony.contreras@gmail.com",
      subject: "SMS simulator to Vendor #{vendor_name}"
    )
  end
end
