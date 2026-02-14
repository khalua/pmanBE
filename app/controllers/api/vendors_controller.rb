class Api::VendorsController < Api::BaseController
  def index
    vendors = Vendor.all
    vendors = vendors.where(vendor_type: params[:vendor_type]) if params[:vendor_type].present?
    vendors = vendors.where(is_available: true) if params[:available] == "true"

    render json: vendors.map { |v| vendor_json(v) }
  end

  def show
    vendor = Vendor.find(params[:id])
    render json: vendor_json(vendor)
  end

  private

  def vendor_json(v)
    {
      id: v.id,
      name: v.name,
      phone_number: v.phone_number,
      rating: v.rating.to_f,
      is_available: v.is_available,
      location: v.location,
      vendor_type: v.vendor_type,
      specialties: v.specialties
    }
  end
end
