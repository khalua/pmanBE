class Web::Manager::TenantsController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!
  before_action :set_tenant, only: [ :show, :move_out, :activate ]

  def index
    @tenants = User.tenant
      .joins(unit: :property)
      .where(properties: { property_manager_id: current_user.id })
      .includes(unit: :property)
      .order(:name)
  end

  def show
  end

  def move_out
    @tenant.update!(
      move_out_date: params[:move_out_date].presence || Date.current,
      active: false
    )
    redirect_to web_manager_tenant_path(@tenant), notice: "Tenant moved out and deactivated."
  end

  def activate
    @tenant.update!(active: true)
    redirect_to web_manager_tenant_path(@tenant), notice: "Tenant reactivated."
  end

  private

  def set_tenant
    @tenant = User.tenant
      .joins(unit: :property)
      .where(properties: { property_manager_id: current_user.id })
      .includes(unit: :property, maintenance_requests: :assigned_vendor)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to web_manager_dashboard_path, alert: "Tenant not found."
  end

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
