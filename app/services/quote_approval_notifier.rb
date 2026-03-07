class QuoteApprovalNotifier
  include Rails.application.routes.url_helpers

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
    notify_vendor if @vendor&.cell_phone.present?
    notify_tenant
  end

  private

  def notify_vendor
    opts = Rails.application.config.action_mailer.default_url_options || { host: "localhost", port: 3000 }
    # Find the winning quote_request to get the portal token
    quote_request = @mr.quote_requests.find_by(vendor: @vendor)
    portal_link = quote_request ? quote_url(token: quote_request.token, approved: "true", **opts) : nil

    address = @mr.tenant&.unit&.property&.address || @mr.tenant&.address || "address on file"

    body = "Congratulations! Your quote for #{@mr.issue_type} at #{address} has been approved.\n\n" \
           "IMPORTANT: Please contact the tenant as soon as possible to schedule the work.\n\n" \
           "Tenant contact info:\n" \
           "Name: #{@tenant.name}\n" \
           "Cell: #{@tenant.cell_phone}\n" \
           "Email: #{@tenant.email}\n\n"

    body += "View full request details:\n#{portal_link}\n\n" if portal_link
    body += "Thank you!"

    VendorNotificationMailer.sms_simulation(@vendor.name, body).deliver_later
  end

  def notify_tenant
    contact = @vendor.cell_phone.presence
    contact_str = contact ? " (#{contact})" : ""
    PushNotificationService.notify(
      user: @tenant,
      title: "Vendor Identified",
      body: "#{@vendor.name}#{contact_str} has been selected for your #{@mr.issue_type} request and will contact you shortly to schedule.",
      data: { maintenance_request_id: @mr.id.to_s, type: "quote_approved" }
    )
  end
end
