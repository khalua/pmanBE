class Web::Manager::TenantsController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!

  def show
    @tenant = User.tenant
      .joins(unit: :property)
      .where(properties: { property_manager_id: current_user.id })
      .includes(unit: :property, maintenance_requests: :assigned_vendor)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to web_manager_dashboard_path, alert: "Tenant not found."
  end

  private

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
