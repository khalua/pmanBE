class Web::Manager::MaintenanceRequestsController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!

  def show
    @maintenance_request = find_request
    @vendors = current_user.vendors.order(:name)
  end

  def close
    @maintenance_request = find_request
    content = params[:content].to_s.strip
    if content.blank?
      redirect_to web_manager_maintenance_request_path(@maintenance_request), alert: "A closing note is required."
      return
    end

    @maintenance_request.notes.create!(user: current_user, content: content)
    @maintenance_request.update!(status: :closed)

    PushNotificationService.notify(
      user: @maintenance_request.tenant,
      title: "Request Closed",
      body: "Your #{@maintenance_request.issue_type} request has been closed: #{content.truncate(80)}",
      data: { maintenance_request_id: @maintenance_request.id.to_s, type: "request_closed" }
    )

    redirect_to web_manager_maintenance_request_path(@maintenance_request), notice: "Request closed."
  end

  def mark_in_progress
    @maintenance_request = find_request
    unless @maintenance_request.quote_accepted? || @maintenance_request.quote_received?
      redirect_to web_manager_maintenance_request_path(@maintenance_request), alert: "Vendor must have acknowledged the request before marking in progress."
      return
    end
    @maintenance_request.update!(status: :in_progress)
    PushNotificationService.notify(
      user: @maintenance_request.tenant,
      title: "Work Started",
      body: "Work has started on your #{@maintenance_request.issue_type} request.",
      data: { maintenance_request_id: @maintenance_request.id.to_s, type: "work_started" }
    )
    redirect_to web_manager_maintenance_request_path(@maintenance_request), notice: "Request marked as in progress."
  end

  def mark_complete
    @maintenance_request = find_request
    unless @maintenance_request.in_progress?
      redirect_to web_manager_maintenance_request_path(@maintenance_request), alert: "Request must be in progress before marking complete."
      return
    end
    @maintenance_request.update!(status: :completed)
    PushNotificationService.notify(
      user: @maintenance_request.tenant,
      title: "Request Completed",
      body: "Your #{@maintenance_request.issue_type} request has been marked as complete.",
      data: { maintenance_request_id: @maintenance_request.id.to_s, type: "request_completed" }
    )
    redirect_to web_manager_maintenance_request_path(@maintenance_request), notice: "Request marked as complete."
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
