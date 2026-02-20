class VendorWorkCompleteNotifier
  def self.call(quote_request)
    new(quote_request).call
  end

  def initialize(quote_request)
    @qr = quote_request
    @mr = quote_request.maintenance_request
    @vendor = quote_request.vendor
  end

  def call
    notify_tenant
    notify_manager
    add_note
  end

  private

  def notify_tenant
    PushNotificationService.notify(
      user: @mr.tenant,
      title: "Work Completed",
      body: "#{@vendor.name} has marked the #{@mr.issue_type} work as complete. Was everything done to your satisfaction?",
      data: { maintenance_request_id: @mr.id.to_s, type: "work_complete" }
    )
  end

  def notify_manager
    manager = @mr.tenant&.unit&.property&.property_manager
    return unless manager

    PushNotificationService.notify(
      user: manager,
      title: "Work Marked Complete",
      body: "#{@vendor.name} has marked the #{@mr.issue_type} work as complete.",
      data: { maintenance_request_id: @mr.id.to_s, type: "vendor_work_complete" }
    )
  end

  def add_note
    manager = @mr.tenant&.unit&.property&.property_manager
    return unless manager

    @mr.notes.create!(
      user: manager,
      content: "#{@vendor.name} has marked the work as complete. The tenant has been asked to confirm."
    )
  end
end
