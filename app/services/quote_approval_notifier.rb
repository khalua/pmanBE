class QuoteApprovalNotifier
  def self.call(quote, message_type:)
    new(quote, message_type).call
  end

  def initialize(quote, message_type)
    @quote = quote
    @message_type = message_type
    @mr = quote.maintenance_request
    @vendor = quote.vendor
    @tenant = quote.maintenance_request.tenant
  end

  def call
    return unless @vendor&.phone_number.present?

    body = case @message_type
           when "contact_tenant"
             contact_tenant_message
           when "manager_will_contact"
             manager_will_contact_message
           else
             raise ArgumentError, "Invalid message_type: #{@message_type}"
           end

    SmsService.send_message(to: @vendor.phone_number, body: body)

    PushNotificationService.notify(
      user: @tenant,
      title: "Quote Approved",
      body: "Your #{@mr.issue_type} quote has been approved. Work will be scheduled soon.",
      data: { maintenance_request_id: @mr.id.to_s, type: "quote_approved" }
    )
  end

  private

  def contact_tenant_message
    "Congratulations! Your quote for #{@mr.issue_type} has been approved.\n\n" \
    "Please contact the tenant directly to schedule the work:\n" \
    "Name: #{@tenant.name}\n" \
    "Phone: #{@tenant.phone_number}\n" \
    "Email: #{@tenant.email}\n\n" \
    "Thank you!"
  end

  def manager_will_contact_message
    "Congratulations! Your quote for #{@mr.issue_type} has been approved.\n\n" \
    "I will contact you shortly to provide more details and coordinate next steps.\n\n" \
    "Thank you!"
  end
end
