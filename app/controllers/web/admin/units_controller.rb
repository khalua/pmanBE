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
    @tenants = User.tenant.where(unit_id: nil).or(User.tenant.where(unit_id: @unit.id)).order(:name)
  end

  def update
    assign_tenant(params[:unit][:tenant_id]) if params[:unit][:tenant_id].present?

    if @unit.update(unit_params)
      redirect_to web_admin_property_path(@property), notice: "Unit updated."
    else
      @tenants = User.tenant.where(unit_id: nil).or(User.tenant.where(unit_id: @unit.id)).order(:name)
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

  def assign_tenant(tenant_id)
    User.where(unit_id: @unit.id).update_all(unit_id: nil)

    if tenant_id.present? && tenant_id != ""
      user = User.tenant.find(tenant_id)
      user.update!(unit_id: @unit.id)
    end
  end

  def require_super_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user&.super_admin?
  end
end
