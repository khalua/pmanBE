class Web::Manager::QuotesController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!
  before_action :set_quote

  def approve
    @quote.maintenance_request.update!(status: :quote_accepted, assigned_vendor: @quote.vendor)
    redirect_to web_manager_maintenance_request_path(@quote.maintenance_request), notice: "Quote approved."
  end

  def reject
    @quote.maintenance_request.update!(status: :quote_rejected)
    redirect_to web_manager_maintenance_request_path(@quote.maintenance_request), notice: "Quote rejected."
  end

  private

  def set_quote
    @quote = Quote.joins(maintenance_request: { tenant: :unit })
      .where(units: { property_id: current_user.properties.select(:id) })
      .find(params[:id])
  end

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
