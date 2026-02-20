class VendorContactedNotifier
  def self.call(quote_request)
    new(quote_request).call
  end

  def initialize(quote_request)
    @qr = quote_request
    @mr = quote_request.maintenance_request
    @vendor = quote_request.vendor
  end

  def call
    notify_manager
    add_note
  end

  private

  def notify_manager
    manager = @mr.tenant&.unit&.property&.property_manager
    return unless manager

    PushNotificationService.notify(
      user: manager,
      title: "Vendor Contacted Tenant",
      body: "#{@vendor.name} has confirmed they contacted the tenant for the #{@mr.issue_type} request.",
      data: { maintenance_request_id: @mr.id.to_s, type: "vendor_contacted" }
    )
  end

  def add_note
    manager = @mr.tenant&.unit&.property&.property_manager
    return unless manager

    @mr.notes.create!(
      user: manager,
      content: "#{@vendor.name} has contacted the tenant to schedule the work."
    )
  end
end
