class Api::Manager::UnitsController < Api::Manager::BaseController
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
    @property = current_user.properties.find(params[:property_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Property not found" }, status: :not_found
  end

  def set_unit
    @unit = @property.units.find(params[:id])
  end

  def unit_params
    params.require(:unit).permit(:identifier, :floor)
  end

  def unit_json(unit)
    unit.reload
    {
      id: unit.id,
      identifier: unit.identifier,
      floor: unit.floor,
      tenants: unit.tenants.map { |t| { id: t.id, name: t.name, email: t.email } }
    }
  end
end
