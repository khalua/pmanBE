class Api::MaintenanceRequestsController < Api::BaseController
  include Rails.application.routes.url_helpers
  before_action :set_request, only: [ :show, :update, :assign_vendor ]

  def index
    requests = if current_user.tenant?
      current_user.maintenance_requests
    else
      MaintenanceRequest.all
    end

    render json: requests.includes(tenant: { unit: :property }, assigned_vendor: {}, quotes: {}).order(created_at: :desc).map { |r| request_json(r) }
  end

  def show
    render json: request_json(@maintenance_request)
  end

  def create
    raw_severity = params[:severity]
    request = current_user.maintenance_requests.build(request_params.except(:severity, :chat_history))
    request.severity = normalize_severity(raw_severity)
    if params[:chat_history].present?
      request.chat_history = params[:chat_history].is_a?(String) ? JSON.parse(params[:chat_history]) : params[:chat_history]
    end
    if request.save
      MaintenanceRequestCreatedNotifier.call(request)
      render json: request_json(request), status: :created
    else
      render json: { errors: request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    old_status = @maintenance_request.status
    if @maintenance_request.update(update_params)
      if @maintenance_request.status != old_status
        MaintenanceStatusNotifier.call(@maintenance_request, old_status)
      end
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

  def normalize_severity(value)
    return :moderate if value.blank?
    v = value.to_s.downcase.strip
    valid = %w[minor moderate urgent emergency]
    return v.to_sym if valid.include?(v)

    # Use Claude to classify free-text severity
    begin
      client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
      response = client.messages.create(
        model: "claude-3-haiku-20240307",
        max_tokens: 10,
        messages: [{ role: "user", content: "A tenant described the severity of their maintenance issue as: \"#{value}\"\n\nClassify this into exactly one of: minor, moderate, urgent, emergency\n\nRespond with only the single word." }]
      )
      result = response.content.first.text.strip.downcase
      return result.to_sym if valid.include?(result)
    rescue => e
      Rails.logger.warn("Severity classification failed: #{e.message}")
    end

    :moderate
  end

  def request_params
    params.permit(:issue_type, :location, :severity, :conversation_summary, :allows_direct_contact, :chat_history, images: [])
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
      tenant: {
        id: r.tenant.id, name: r.tenant.name, phone: r.tenant.phone, address: r.tenant.address,
        unit: r.tenant.unit ? { id: r.tenant.unit.id, identifier: r.tenant.unit.identifier, floor: r.tenant.unit.floor } : nil,
        property: r.tenant.unit&.property ? { id: r.tenant.unit.property.id, name: r.tenant.unit.property.name, address: r.tenant.unit.property.address, property_type: r.tenant.unit.property.property_type } : nil
      },
      assigned_vendor: r.assigned_vendor ? { id: r.assigned_vendor.id, name: r.assigned_vendor.name, phone_number: r.assigned_vendor.phone_number, rating: r.assigned_vendor.rating.to_f, is_available: r.assigned_vendor.is_available, location: r.assigned_vendor.location, vendor_type: r.assigned_vendor.vendor_type, specialties: r.assigned_vendor.specialties } : nil,
      image_urls: r.images.map { |img| rails_blob_url(img, disposition: "inline") },
      quotes: r.quotes.map { |q| { id: q.id, estimated_cost: q.estimated_cost.to_f, work_description: q.work_description, estimated_arrival_time: q.estimated_arrival_time } },
      notes: r.notes.order(created_at: :asc).map { |n| { id: n.id, content: n.content, user: { id: n.user.id, name: n.user.name, role: n.user.role }, created_at: n.created_at } },
      chat_history: r.chat_history.reject { |m| m["role"] == "system" || m["content"]&.match?(/\AREADY_FOR_(PHOTOS|SUBMISSION)\z/) }.presence,
      created_at: r.created_at,
      updated_at: r.updated_at
    }.compact
  end
end
