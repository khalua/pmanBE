class MaintenanceStatusNotifier
  def self.call(maintenance_request, old_status)
    new(maintenance_request, old_status).call
  end

  def initialize(maintenance_request, old_status)
    @mr = maintenance_request
    @old_status = old_status
    @tenant = maintenance_request.tenant
  end

  def call
    PushNotificationService.notify(
      user: @tenant,
      title: "Maintenance Update",
      body: "Your #{@mr.issue_type} request is now: #{@mr.status.humanize}",
      data: { maintenance_request_id: @mr.id.to_s, type: "status_change" }
    )
  end
end
