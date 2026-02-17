class Web::Tenant::MaintenanceRequestsController < WebController
  before_action :authenticate_user!
  before_action :require_tenant!

  def show
    @maintenance_request = current_user.maintenance_requests
      .includes(:notes, :assigned_vendor, :quotes, images_attachments: :blob)
      .find(params[:id])
  end

  def create_note
    @maintenance_request = current_user.maintenance_requests.find(params[:id])
    note = @maintenance_request.notes.create!(content: params[:content], user: current_user)
    NoteNotifier.call(note)
    redirect_to web_tenant_maintenance_request_path(@maintenance_request), notice: "Note added."
  end

  private

  def require_tenant!
    redirect_to root_path, alert: "Not authorized." unless current_user&.tenant?
  end
end
