class Api::Manager::VendorsController < Api::Manager::BaseController
  def index
    vendors = current_user.vendors
    render json: vendors.map { |v| vendor_json(v) }
  end

  def show
    vendor = current_user.vendors.find(params[:id])
    property_ids = current_user.properties.pluck(:id)
    requests = vendor.assigned_requests.where(tenant: User.joins(:unit).where(units: { property_id: property_ids }))

    render json: vendor_json(vendor).merge(maintenance_requests: requests.as_json(only: [ :id, :issue_type, :status, :severity, :created_at ]))
  end

  def create
    vendor = Vendor.find(params[:vendor_id])
    pmv = current_user.property_manager_vendors.build(vendor: vendor)

    if pmv.save
      render json: vendor_json(vendor), status: :created
    else
      render json: { errors: pmv.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    pmv = current_user.property_manager_vendors.find_by!(vendor_id: params[:id])
    pmv.destroy!
    head :no_content
  end

  private

  def vendor_json(v)
    {
      id: v.id,
      name: v.name,
      phone_number: v.phone_number,
      vendor_type: v.vendor_type,
      rating: v.rating,
      is_available: v.is_available,
      location: v.location,
      specialties: v.specialties
    }
  end
end
