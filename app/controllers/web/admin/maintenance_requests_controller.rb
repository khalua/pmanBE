class Web::Admin::MaintenanceRequestsController < WebController
  before_action :authenticate_user!
  before_action :require_super_admin!
  before_action :set_request, only: [ :show, :destroy ]

  def index
    @requests = MaintenanceRequest.includes(:tenant, :assigned_vendor, :quotes).order(created_at: :desc)
  end

  def show
    @notes = @maintenance_request.notes.includes(:user).order(created_at: :asc)
    @quotes = @maintenance_request.quotes.includes(:vendor)
  end

  def destroy
    @maintenance_request.destroy!
    redirect_to web_admin_maintenance_requests_path, notice: "Maintenance request deleted."
  end

  private

  def set_request
    @maintenance_request = MaintenanceRequest.find(params[:id])
  end

  def require_super_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user&.super_admin?
  end
end
