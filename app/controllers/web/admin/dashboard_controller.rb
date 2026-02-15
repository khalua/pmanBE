class Web::Admin::DashboardController < WebController
  before_action :authenticate_user!
  before_action :require_super_admin!

  def show
    @tenant_count = User.tenant.count
    @property_manager_count = User.property_manager.count
    @vendor_count = Vendor.count
    @property_count = Property.count
    @unit_count = Unit.count
    @total_maintenance_requests = MaintenanceRequest.count
    @recent_requests = MaintenanceRequest.includes(:tenant).order(created_at: :desc).limit(10)
    @users = User.order(created_at: :desc).limit(10)
  end

  private

  def require_super_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user&.super_admin?
  end
end
