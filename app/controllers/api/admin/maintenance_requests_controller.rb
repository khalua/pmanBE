class Api::Admin::MaintenanceRequestsController < Api::Admin::BaseController
  before_action :set_request, only: [ :show, :destroy ]

  def index
    requests = MaintenanceRequest.includes(:tenant, :assigned_vendor, :quotes).order(created_at: :desc)
    render json: requests.map { |r| request_summary_json(r) }
  end

  def show
    render json: request_detail_json(@maintenance_request)
  end

  def destroy
    @maintenance_request.destroy!
    render json: { message: "Maintenance request deleted" }
  end

  private

  def set_request
    @maintenance_request = MaintenanceRequest.includes(:tenant, :assigned_vendor, :quotes, :notes).find(params[:id])
  end

  def request_summary_json(r)
    {
      id: r.id,
      issue_type: r.issue_type,
      location: r.location,
      severity: r.severity,
      status: r.status,
      conversation_summary: r.conversation_summary,
      tenant: { id: r.tenant.id, name: r.tenant.name, email: r.tenant.email },
      assigned_vendor: r.assigned_vendor ? { id: r.assigned_vendor.id, name: r.assigned_vendor.name } : nil,
      quotes_count: r.quotes.size,
      created_at: r.created_at,
      updated_at: r.updated_at
    }
  end

  def request_detail_json(r)
    {
      id: r.id,
      issue_type: r.issue_type,
      location: r.location,
      severity: r.severity,
      status: r.status,
      conversation_summary: r.conversation_summary,
      allows_direct_contact: r.allows_direct_contact,
      tenant: {
        id: r.tenant.id, name: r.tenant.name, email: r.tenant.email, phone: r.tenant.phone,
        unit: r.tenant.unit ? { id: r.tenant.unit.id, identifier: r.tenant.unit.identifier, floor: r.tenant.unit.floor } : nil,
        property: r.tenant.unit&.property ? { id: r.tenant.unit.property.id, name: r.tenant.unit.property.name, address: r.tenant.unit.property.address } : nil
      },
      assigned_vendor: r.assigned_vendor ? { id: r.assigned_vendor.id, name: r.assigned_vendor.name, phone_number: r.assigned_vendor.phone_number, vendor_type: r.assigned_vendor.vendor_type } : nil,
      image_urls: r.images.map { |img| rails_blob_url(img, disposition: "inline") },
      quotes: r.quotes.map { |q| { id: q.id, estimated_cost: q.estimated_cost.to_f, work_description: q.work_description, estimated_arrival_time: q.estimated_arrival_time } },
      notes: r.notes.order(created_at: :asc).map { |n| { id: n.id, content: n.content, user: { id: n.user.id, name: n.user.name, role: n.user.role }, created_at: n.created_at } },
      chat_history: r.chat_history,
      created_at: r.created_at,
      updated_at: r.updated_at
    }.compact
  end
end
