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
    return unless @vendor.phone_number.present?

    base_url = ENV.fetch("FRONTEND_URL", "http://localhost:3000")
    link = "#{base_url}/quote?token=#{@qr.token}"

    body = "New maintenance request:\n" \
           "Issue: #{@mr.issue_type}\n" \
           "Severity: #{@mr.severity}\n" \
           "Submit your quote here: #{link}"

    SmsService.send_message(to: @vendor.phone_number, body: body)
  end
end
