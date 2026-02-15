class Web::Manager::VendorsController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!

  def index
    @vendors = current_user.vendors.order(:name)
    @available_vendors = Vendor.where.not(id: @vendors.select(:id)).order(:name)
  end

  def create
    vendor = Vendor.find(params[:vendor_id])
    pmv = current_user.property_manager_vendors.build(vendor: vendor)

    if pmv.save
      redirect_to web_manager_vendors_path, notice: "Vendor added."
    else
      redirect_to web_manager_vendors_path, alert: pmv.errors.full_messages.join(", ")
    end
  end

  def destroy
    pmv = current_user.property_manager_vendors.find_by!(vendor_id: params[:id])
    pmv.destroy!
    redirect_to web_manager_vendors_path, notice: "Vendor removed."
  end

  private

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
