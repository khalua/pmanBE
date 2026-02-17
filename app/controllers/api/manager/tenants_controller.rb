class Api::Manager::TenantsController < Api::Manager::BaseController
  before_action :set_tenant

  def show
    render json: tenant_json(@tenant)
  end

  def move_out
    @tenant.update!(
      move_out_date: params[:move_out_date] || Date.current,
      active: false
    )
    render json: tenant_json(@tenant)
  end

  def activate
    @tenant.update!(active: true)
    render json: tenant_json(@tenant)
  end

  def update
    @tenant.update!(tenant_params)
    render json: tenant_json(@tenant)
  end

  private

  def set_tenant
    if current_user.super_admin?
      @tenant = User.tenant.find(params[:id])
    else
      property_ids = current_user.properties.pluck(:id)
      unit_ids = Unit.where(property_id: property_ids).pluck(:id)
      @tenant = User.tenant.where(unit_id: unit_ids).find(params[:id])
    end
  end

  def tenant_params
    params.require(:tenant).permit(:move_in_date, :move_out_date, :active)
  end

  def tenant_json(tenant)
    {
      id: tenant.id,
      name: tenant.name,
      email: tenant.email,
      mobile_phone: tenant.mobile_phone,
      move_in_date: tenant.move_in_date,
      move_out_date: tenant.move_out_date,
      active: tenant.active,
      phone_verified: tenant.phone_verified,
      unit: tenant.unit ? { id: tenant.unit.id, identifier: tenant.unit.identifier } : nil
    }
  end
end
