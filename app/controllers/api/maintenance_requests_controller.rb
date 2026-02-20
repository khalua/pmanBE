class Api::MaintenanceRequestsController < Api::BaseController
  include Rails.application.routes.url_helpers
  before_action :set_request, only: [ :show, :update, :assign_vendor, :close, :mark_complete, :rate_vendor ]

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

  def close
    unless current_user.property_manager? || current_user.super_admin?
      return render json: { error: "Forbidden" }, status: :forbidden
    end

    if @maintenance_request.completed? || @maintenance_request.closed?
      return render json: { error: "Request is already completed" }, status: :unprocessable_entity
    end

    note_content = params[:note].to_s.strip
    if note_content.blank?
      return render json: { error: "A closing note is required" }, status: :unprocessable_entity
    end

    @maintenance_request.notes.create!(user: current_user, content: note_content)
    @maintenance_request.update!(status: :closed)

    PushNotificationService.notify(
      user: @maintenance_request.tenant,
      title: "Request Closed",
      body: "Your #{@maintenance_request.issue_type} request has been closed: #{note_content.truncate(80)}",
      data: { maintenance_request_id: @maintenance_request.id.to_s, type: "request_closed" }
    )

    render json: request_json(@maintenance_request)
  end

  def mark_complete
    # Tenant can mark their own request complete; managers/admins can mark any
    unless current_user.tenant? && @maintenance_request.tenant_id == current_user.id ||
           current_user.property_manager? || current_user.super_admin?
      return render json: { error: "Forbidden" }, status: :forbidden
    end

    if @maintenance_request.completed? || @maintenance_request.closed?
      return render json: { error: "Request is already completed" }, status: :unprocessable_entity
    end

    @maintenance_request.update!(status: :completed)

    # Notify the manager if tenant marked complete
    if current_user.tenant?
      manager = @maintenance_request.tenant.unit&.property&.property_manager
      if manager
        PushNotificationService.notify(
          user: manager,
          title: "Job Marked Complete",
          body: "#{current_user.name} marked the #{@maintenance_request.issue_type} request as complete.",
          data: { maintenance_request_id: @maintenance_request.id.to_s, type: "request_completed" }
        )
      end
    else
      PushNotificationService.notify(
        user: @maintenance_request.tenant,
        title: "Request Completed",
        body: "Your #{@maintenance_request.issue_type} request has been marked as complete.",
        data: { maintenance_request_id: @maintenance_request.id.to_s, type: "request_completed" }
      )
    end

    render json: request_json(@maintenance_request)
  end

  def assign_vendor
    vendor = Vendor.find(params[:vendor_id])
    @maintenance_request.update!(assigned_vendor: vendor, status: :vendor_quote_requested)
    render json: request_json(@maintenance_request)
  end

  def rate_vendor
    unless current_user.tenant? && @maintenance_request.tenant_id == current_user.id
      return render json: { error: "Forbidden" }, status: :forbidden
    end

    unless @maintenance_request.assigned_vendor_id.present?
      return render json: { error: "No vendor assigned to this request" }, status: :unprocessable_entity
    end

    rating = VendorRating.find_or_initialize_by(
      vendor_id: @maintenance_request.assigned_vendor_id,
      maintenance_request_id: @maintenance_request.id
    )
    rating.assign_attributes(tenant: current_user, stars: params[:stars], comment: params[:comment])

    if rating.save
      render json: { stars: rating.stars, comment: rating.comment }
    else
      render json: { errors: rating.errors.full_messages }, status: :unprocessable_entity
    end
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
        model: "claude-haiku-4-5-20251001",
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
      assigned_vendor: r.assigned_vendor ? { id: r.assigned_vendor.id, name: r.assigned_vendor.name, contact_name: r.assigned_vendor.contact_name, cell_phone: r.assigned_vendor.cell_phone, phone_number: r.assigned_vendor.phone_number, email: r.assigned_vendor.email, rating: r.assigned_vendor.rating.to_f, is_available: r.assigned_vendor.is_available, location: r.assigned_vendor.location, vendor_type: r.assigned_vendor.vendor_type, specialties: r.assigned_vendor.specialties } : nil,
      image_urls: r.images.map { |img| rails_blob_url(img, disposition: "inline") },
      quotes: r.quotes.includes(:vendor).map { |q| { id: q.id, vendor_id: q.vendor_id, vendor_name: q.vendor&.name, vendor_rating: q.vendor&.rating.to_f, estimated_cost: q.estimated_cost.to_f, work_description: q.work_description, estimated_arrival_time: q.estimated_arrival_time, created_at: q.created_at } },
      notes: r.notes.order(created_at: :asc).map { |n| { id: n.id, content: n.content, user: { id: n.user.id, name: n.user.name, role: n.user.role }, created_at: n.created_at } },
      chat_history: r.chat_history.reject { |m| m["role"] == "system" || m["content"]&.match?(/\AREADY_FOR_(PHOTOS|SUBMISSION)\z/) }.presence,
      created_at: r.created_at,
      updated_at: r.updated_at
    }.compact
  end
end
