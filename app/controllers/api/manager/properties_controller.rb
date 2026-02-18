class Api::Manager::PropertiesController < Api::Manager::BaseController
  before_action :set_property, only: [ :show, :update, :destroy ]

  def index
    properties = current_user.properties.includes(units: :tenants).order(:address)
    render json: properties.map { |p| property_json(p) }
  end

  def show
    render json: property_json(@property, include_units: true)
  end

  def create
    property = current_user.properties.build(property_params)
    if property.save
      render json: property_json(property, include_units: true), status: :created
    else
      render json: { errors: property.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @property.update(property_params)
      render json: property_json(@property, include_units: true)
    else
      render json: { errors: @property.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @property.destroy!
    render json: { message: "Property deleted" }
  end

  private

  def set_property
    @property = current_user.properties.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Property not found" }, status: :not_found
  end

  def property_params
    params.require(:property).permit(:address, :name, :property_type)
  end

  def property_json(property, include_units: false)
    json = {
      id: property.id,
      address: property.address,
      name: property.name,
      property_type: property.property_type,
      units_count: property.units.size,
      created_at: property.created_at
    }
    if include_units
      json[:units] = property.units.includes(:tenants).map { |u| unit_json(u) }
    end
    json
  end

  def unit_json(unit)
    {
      id: unit.id,
      identifier: unit.identifier,
      floor: unit.floor,
      tenants: unit.tenants.map { |t| { id: t.id, name: t.name, email: t.email } }
    }
  end
end
