class Web::Tenant::DashboardController < WebController
  before_action :authenticate_user!
  before_action :require_tenant!

  def show
    @unit = current_user.unit&.then { |u| Unit.includes(:property).find(u.id) }
    @maintenance_requests = current_user.maintenance_requests.includes(:quotes).order(created_at: :desc)
  end

  private

  def require_tenant!
    redirect_to root_path, alert: "Not authorized." unless current_user&.tenant?
  end
end
