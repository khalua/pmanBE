class Web::Manager::VendorsController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!
  before_action :set_vendor, only: [ :show, :edit, :update, :destroy, :toggle_active ]

  def index
    @vendors = current_user.vendors
      .joins(:property_manager_vendors)
      .where(property_manager_vendors: { user_id: current_user.id })
      .select("vendors.*, property_manager_vendors.is_active")
      .order(:name)
  end

  def show
    @pmv = current_user.property_manager_vendors.find_by!(vendor_id: @vendor.id)
    @quotes_received = @vendor.quotes.count
    @requests_fulfilled = @vendor.assigned_requests
      .joins(tenant: :unit)
      .where(units: { property_id: current_user.properties.select(:id) })
      .where(status: :completed).count
    @average_rating = @vendor.average_rating
    @recent_requests = @vendor.assigned_requests
      .joins(tenant: :unit)
      .where(units: { property_id: current_user.properties.select(:id) })
      .order(created_at: :desc).limit(10)
  end

  def new
    @vendor = Vendor.new
  end

  def create
    @vendor = current_user.owned_vendors.build(vendor_params)
    if @vendor.save
      current_user.property_manager_vendors.create!(vendor: @vendor, is_active: true)
      redirect_to web_manager_vendors_path, notice: "Vendor created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @vendor.update(vendor_params)
      redirect_to web_manager_vendor_path(@vendor), notice: "Vendor updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    pmv = current_user.property_manager_vendors.find_by!(vendor_id: @vendor.id)
    pmv.destroy!
    @vendor.destroy! if @vendor.owner_user_id == current_user.id
    redirect_to web_manager_vendors_path, notice: "Vendor removed."
  end

  def toggle_active
    pmv = current_user.property_manager_vendors.find_by!(vendor_id: @vendor.id)
    pmv.update!(is_active: !pmv.is_active)
    status = pmv.is_active ? "activated" : "deactivated"
    redirect_to web_manager_vendors_path, notice: "#{@vendor.name} #{status}."
  end

  private

  def set_vendor
    @vendor = current_user.vendors.find(params[:id])
  end

  def vendor_params
    params.require(:vendor).permit(
      :name, :vendor_type, :contact_name, :cell_phone, :phone_number,
      :email, :address, :website, :notes, :is_available,
      specialties: []
    )
  end

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
