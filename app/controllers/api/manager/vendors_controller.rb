class Api::Manager::VendorsController < Api::Manager::BaseController
  def index
    vendors = current_user.vendors
      .joins(:property_manager_vendors)
      .where(property_manager_vendors: { user_id: current_user.id })
      .select("vendors.*, property_manager_vendors.is_active AS pmv_is_active")
    render json: vendors.map { |v| vendor_json(v) }
  end

  def show
    vendor = current_user.vendors.find(params[:id])
    property_ids = current_user.properties.pluck(:id)
    requests = vendor.assigned_requests.where(tenant: User.joins(:unit).where(units: { property_id: property_ids }))

    render json: vendor_json(vendor).merge(
      maintenance_requests: requests.as_json(only: [ :id, :issue_type, :status, :severity, :created_at ]),
      stats: {
        quotes_received: vendor.quotes_received_count,
        requests_fulfilled: vendor.requests_fulfilled_count,
        average_rating: vendor.average_rating
      }
    )
  end

  def create
    vendor = current_user.owned_vendors.build(vendor_params)
    if vendor.save
      pmv = current_user.property_manager_vendors.create!(vendor: vendor, is_active: true)
      render json: vendor_json(vendor, pmv.is_active), status: :created
    else
      render json: { errors: vendor.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    vendor = current_user.owned_vendors.find(params[:id])
    if vendor.update(vendor_params)
      render json: vendor_json(vendor)
    else
      render json: { errors: vendor.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def toggle_active
    pmv = current_user.property_manager_vendors.find_by!(vendor_id: params[:id])
    pmv.update!(is_active: !pmv.is_active)
    render json: { is_active: pmv.is_active }
  end

  def destroy
    pmv = current_user.property_manager_vendors.find_by!(vendor_id: params[:id])
    vendor = pmv.vendor
    pmv.destroy!
    vendor.destroy! if vendor.owner_user_id == current_user.id
    head :no_content
  end

  private

  def vendor_params
    params.require(:vendor).permit(
      :name, :vendor_type, :contact_name, :cell_phone, :phone_number,
      :email, :address, :website, :notes, :is_available,
      specialties: []
    )
  end

  def vendor_json(v, is_active = nil)
    {
      id: v.id,
      name: v.name,
      contact_name: v.contact_name,
      cell_phone: v.cell_phone,
      phone_number: v.phone_number,
      email: v.email,
      vendor_type: v.vendor_type,
      address: v.address,
      website: v.website,
      notes: v.notes,
      rating: v.average_rating,
      is_available: v.is_available,
      is_active: is_active,
      specialties: v.specialties
    }
  end
end
