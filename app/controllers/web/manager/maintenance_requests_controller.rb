class Web::Manager::MaintenanceRequestsController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!

  def show
    @maintenance_request = find_request
    @vendors = current_user.vendors.order(:name)
  end

  def create_note
    @maintenance_request = find_request
    note = @maintenance_request.notes.create!(user: current_user, content: params[:content])
    NoteNotifier.call(note)
    redirect_to web_manager_maintenance_request_path(@maintenance_request), notice: "Note added."
  end

  private

  def find_request
    MaintenanceRequest
      .joins(tenant: :unit)
      .where(units: { property_id: current_user.properties.select(:id) })
      .includes(tenant: { unit: :property }, assigned_vendor: {}, quote_requests: :vendor, quotes: :vendor, notes: :user, images_attachments: :blob)
      .find(params[:id])
  end

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
