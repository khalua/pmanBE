class Api::Admin::MaintenanceRequestsController < Api::Admin::BaseController
  def index
    requests = MaintenanceRequest.includes(:tenant, :assigned_vendor, :quotes).order(created_at: :desc)
    render json: requests.map { |r| request_json(r) }
  end

  private

  def request_json(r)
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
end
