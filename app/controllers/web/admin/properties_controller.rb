class Web::Admin::PropertiesController < WebController
  before_action :authenticate_user!
  before_action :require_super_admin!
  before_action :set_property, only: [ :show, :edit, :update, :destroy ]

  def index
    @properties = Property.includes(:property_manager, :units).order(created_at: :desc)
  end

  def show
    @units = @property.units.includes(:tenant).order(:identifier)
  end

  def new
    @property = Property.new
    @managers = User.property_manager.order(:name)
  end

  def create
    @property = Property.new(property_params)
    if @property.save
      redirect_to web_admin_property_path(@property), notice: "Property created."
    else
      @managers = User.property_manager.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @managers = User.property_manager.order(:name)
  end

  def update
    if @property.update(property_params)
      redirect_to web_admin_property_path(@property), notice: "Property updated."
    else
      @managers = User.property_manager.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @property.destroy!
    redirect_to web_admin_properties_path, notice: "Property deleted."
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def property_params
    params.require(:property).permit(:address, :name, :property_type, :property_manager_id)
  end

  def require_super_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user&.super_admin?
  end
end
