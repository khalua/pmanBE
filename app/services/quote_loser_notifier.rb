class QuoteLoserNotifier
  def self.call(quote_request)
    new(quote_request).call
  end

  def initialize(quote_request)
    @qr = quote_request
    @vendor = quote_request.vendor
    @mr = quote_request.maintenance_request
  end

  def call
    return unless @vendor&.phone_number.present?

    body = "Thank you for submitting a quote for the #{@mr.issue_type} job. " \
           "We've decided to go with another vendor this time, but we appreciate " \
           "your time and hope to work with you in the future."

    VendorNotificationMailer.sms_simulation(@vendor.name, body).deliver_later
  end
end
