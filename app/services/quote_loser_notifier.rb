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
    return unless @vendor&.cell_phone.present?

    address = @mr.tenant&.unit&.property&.address || @mr.tenant&.address
    location_str = address ? " for our #{@mr.issue_type} maintenance request for #{address}" : " for the #{@mr.issue_type} job"

    body = "Thank you for submitting a quote#{location_str}.\n\n" \
           "We've decided to go with another option for now, but we appreciate your time. " \
           "We'll keep you in mind for future opportunities.\n\n" \
           "Best regards"

    VendorNotificationMailer.sms_simulation(@vendor.name, body).deliver_later
  end
end
