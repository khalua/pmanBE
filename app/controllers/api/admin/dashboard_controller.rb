class Api::Admin::DashboardController < Api::Admin::BaseController
  def show
    render json: {
      tenant_count: User.tenant.count,
      property_manager_count: User.property_manager.count,
      vendor_count: Vendor.count,
      property_count: Property.count,
      unit_count: Unit.count,
      total_maintenance_requests: MaintenanceRequest.count
    }
  end
end
