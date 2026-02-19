class Web::Manager::TenantsController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!
  before_action :set_tenant, only: [ :show, :move_out, :activate ]

  def index
    # Show active tenants (no move_out_date or future move_out_date) for this manager's properties
    @tenants = User.tenant
      .joins(unit: :property)
      .where(properties: { property_manager_id: current_user.id })
      .where("users.move_out_date IS NULL OR users.move_out_date >= ?", Date.current)
      .includes(unit: :property)
      .order(:name)
  end

  def show
  end

  def move_out
    move_out_date = params.dig(:tenant, :move_out_date).presence || Date.current
    @tenant.update!(move_out_date: move_out_date)
    if move_out_date.to_date <= Date.current
      redirect_to web_manager_tenant_path(@tenant), notice: "#{@tenant.name} has been moved out."
    else
      redirect_to web_manager_tenant_path(@tenant), notice: "Move-out date set to #{move_out_date.to_date.strftime('%B %d, %Y')}. The unit will show as vacant after that date."
    end
  end

  def activate
    @tenant.update!(move_out_date: nil)
    redirect_to web_manager_tenant_path(@tenant), notice: "Tenant reactivated."
  end

  private

  def set_tenant
    # Allow viewing past tenants too (they keep their unit_id for history)
    @tenant = User.tenant
      .joins(unit: :property)
      .where(properties: { property_manager_id: current_user.id })
      .includes(unit: :property, maintenance_requests: :assigned_vendor)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to web_manager_tenants_path, alert: "Tenant not found."
  end

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
