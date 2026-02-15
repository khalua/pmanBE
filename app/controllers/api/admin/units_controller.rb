class Api::Admin::UnitsController < Api::Admin::BaseController
  before_action :set_property
  before_action :set_unit, only: [ :update, :destroy ]

  def create
    unit = @property.units.build(unit_params)
    if unit.save
      render json: unit_json(unit), status: :created
    else
      render json: { errors: unit.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    assign_tenant(params[:unit][:tenant_id]) if params[:unit].key?(:tenant_id)

    if @unit.update(unit_params)
      render json: unit_json(@unit)
    else
      render json: { errors: @unit.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @unit.destroy!
    render json: { message: "Unit deleted" }
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_unit
    @unit = @property.units.find(params[:id])
  end

  def unit_params
    params.require(:unit).permit(:identifier, :floor)
  end

  def assign_tenant(tenant_id)
    User.where(unit_id: @unit.id).update_all(unit_id: nil)

    if tenant_id.present?
      user = User.tenant.find(tenant_id)
      user.update!(unit_id: @unit.id)
    end
  end

  def unit_json(unit)
    unit.reload
    {
      id: unit.id,
      identifier: unit.identifier,
      floor: unit.floor,
      tenant: unit.tenant ? { id: unit.tenant.id, name: unit.tenant.name, email: unit.tenant.email } : nil
    }
  end
end
