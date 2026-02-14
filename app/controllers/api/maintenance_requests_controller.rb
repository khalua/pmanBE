class Api::MaintenanceRequestsController < Api::BaseController
  before_action :set_request, only: [ :show, :update, :assign_vendor ]

  def index
    requests = if current_user.tenant?
      current_user.maintenance_requests
    else
      MaintenanceRequest.all
    end

    render json: requests.includes(:tenant, :assigned_vendor, :quotes).order(created_at: :desc).map { |r| request_json(r) }
  end

  def show
    render json: request_json(@maintenance_request)
  end

  def create
    request = current_user.maintenance_requests.build(request_params)
    if request.save
      render json: request_json(request), status: :created
    else
      render json: { errors: request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @maintenance_request.update(update_params)
      render json: request_json(@maintenance_request)
    else
      render json: { errors: @maintenance_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def assign_vendor
    vendor = Vendor.find(params[:vendor_id])
    @maintenance_request.update!(assigned_vendor: vendor, status: :vendor_quote_requested)
    render json: request_json(@maintenance_request)
  end

  private

  def set_request
    @maintenance_request = MaintenanceRequest.find(params[:id])
  end

  def request_params
    params.permit(:issue_type, :location, :severity, :conversation_summary, :allows_direct_contact, images: [])
  end

  def update_params
    params.permit(:status)
  end

  def request_json(r)
    {
      id: r.id,
      issue_type: r.issue_type,
      location: r.location,
      severity: r.severity,
      status: r.status,
      conversation_summary: r.conversation_summary,
      allows_direct_contact: r.allows_direct_contact,
      tenant: { id: r.tenant.id, name: r.tenant.name, phone: r.tenant.phone, address: r.tenant.address },
      assigned_vendor: r.assigned_vendor ? { id: r.assigned_vendor.id, name: r.assigned_vendor.name, vendor_type: r.assigned_vendor.vendor_type } : nil,
      quotes: r.quotes.map { |q| { id: q.id, estimated_cost: q.estimated_cost.to_f, work_description: q.work_description, estimated_arrival_time: q.estimated_arrival_time } },
      created_at: r.created_at,
      updated_at: r.updated_at
    }
  end
end
