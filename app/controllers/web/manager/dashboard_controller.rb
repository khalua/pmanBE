class Web::Manager::DashboardController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!

  def show
    @properties = current_user.properties.includes(units: :tenant).order(:address)
    @total_units = @properties.sum { |p| p.units.size }
    @occupied_units = @properties.sum { |p| p.units.count { |u| u.tenant.present? } }
    @maintenance_requests = MaintenanceRequest
      .joins(tenant: :unit)
      .where(units: { property_id: @properties.select(:id) })
      .includes(tenant: { unit: :property }, assigned_vendor: {})
      .order(created_at: :desc)
    @vendors_count = current_user.vendors.count
  end

  private

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
