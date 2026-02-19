class QuoteApprovalNotifier
  def self.call(quote)
    new(quote).call
  end

  def initialize(quote)
    @quote = quote
    @mr = quote.maintenance_request
    @vendor = quote.vendor
    @tenant = quote.maintenance_request.tenant
  end

  def call
    notify_vendor if @vendor&.phone_number.present?
    notify_tenant
  end

  private

  def notify_vendor
    body = "Congratulations! Your quote for #{@mr.issue_type} has been approved.\n\n" \
           "IMPORTANT: Please contact the tenant as soon as possible to schedule the work.\n\n" \
           "Tenant contact info:\n" \
           "Name: #{@tenant.name}\n" \
           "Phone: #{@tenant.phone}\n" \
           "Email: #{@tenant.email}\n\n" \
           "Thank you!"

    VendorNotificationMailer.sms_simulation(@vendor.name, body).deliver_later
  end

  def notify_tenant
    PushNotificationService.notify(
      user: @tenant,
      title: "Vendor Assigned",
      body: "A vendor has been assigned to your #{@mr.issue_type} request. Tap to see vendor details.",
      data: { maintenance_request_id: @mr.id.to_s, type: "quote_approved" }
    )
  end
end
