class QuoteRequestNotifier
  def self.call(quote_request)
    new(quote_request).call
  end

  def initialize(quote_request)
    @qr = quote_request
    @mr = quote_request.maintenance_request
    @vendor = quote_request.vendor
  end

  def call
    return unless @vendor.cell_phone.present?

    opts = Rails.application.config.action_mailer.default_url_options || { host: "localhost", port: 3000 }
    link = Rails.application.routes.url_helpers.quote_url(token: @qr.token, **opts)

    body = "New maintenance request:\n" \
           "Issue: #{@mr.issue_type}\n" \
           "Severity: #{@mr.severity}\n" \
           "Submit your quote here: #{link}"

    VendorNotificationMailer.sms_simulation(@vendor.name, body).deliver_later
  end
end
