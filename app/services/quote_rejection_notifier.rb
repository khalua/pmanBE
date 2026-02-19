class QuoteRejectionNotifier
  def self.call(quote)
    new(quote).call
  end

  def initialize(quote)
    @quote = quote
    @mr = quote.maintenance_request
    @vendor = quote.vendor
  end

  def call
    return unless @vendor&.cell_phone.present?

    body = "Hi #{@vendor.name},\n\n" \
           "Thank you for submitting a quote for our #{@mr.issue_type} maintenance request.\n\n" \
           "We've decided to go with another option for now, but we appreciate your time. " \
           "We'll keep you in mind for future opportunities.\n\n" \
           "Best regards"

    VendorNotificationMailer.sms_simulation(@vendor.name, body).deliver_later

    PushNotificationService.notify(
      user: @mr.tenant,
      title: "Quote Update",
      body: "A quote for your #{@mr.issue_type} request was declined. We're looking for other options.",
      data: { maintenance_request_id: @mr.id.to_s, type: "quote_rejected" }
    )
  end
end
