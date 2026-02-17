class Web::Admin::UnitsController < WebController
  before_action :authenticate_user!
  before_action :require_super_admin!
  before_action :set_property
  before_action :set_unit, only: [ :edit, :update, :destroy ]

  def new
    @unit = @property.units.build
  end

  def create
    @unit = @property.units.build(unit_params)
    if @unit.save
      redirect_to web_admin_property_path(@property), notice: "Unit created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @unit.update(unit_params)
      redirect_to web_admin_property_path(@property), notice: "Unit updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @unit.destroy!
    redirect_to web_admin_property_path(@property), notice: "Unit deleted."
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

  def require_super_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user&.super_admin?
  end
end
