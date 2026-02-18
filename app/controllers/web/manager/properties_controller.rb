class Web::Manager::PropertiesController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!
  before_action :set_property, only: [ :show, :edit, :update, :destroy ]

  def index
    @properties = current_user.properties.includes(:units).order(:address)
  end

  def show
    @units = @property.units.includes(:tenants).order(:identifier)
  end

  def new
    @property = Property.new
  end

  def create
    @property = current_user.properties.build(property_params)
    if @property.save
      redirect_to web_manager_property_path(@property), notice: "Property created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to web_manager_property_path(@property), notice: "Property updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @property.destroy!
    redirect_to web_manager_properties_path, notice: "Property deleted."
  end

  private

  def set_property
    @property = current_user.properties.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to web_manager_properties_path, alert: "Property not found."
  end

  def property_params
    params.require(:property).permit(:address, :name, :property_type)
  end

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
