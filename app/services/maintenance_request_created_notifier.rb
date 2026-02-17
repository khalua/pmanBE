class MaintenanceRequestCreatedNotifier
  def self.call(maintenance_request)
    new(maintenance_request).call
  end

  def initialize(maintenance_request)
    @mr = maintenance_request
    @tenant = maintenance_request.tenant
  end

  def call
    manager = @tenant.unit&.property&.property_manager
    return unless manager

    PushNotificationService.notify(
      user: manager,
      title: "New Maintenance Request",
      body: "#{@tenant.name}: #{@mr.issue_type} - #{@mr.location}",
      data: { maintenance_request_id: @mr.id.to_s, type: "new_request" }
    )
  end
end
