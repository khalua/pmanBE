class Web::Manager::QuoteRequestsController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!

  def create
    mr = MaintenanceRequest
      .joins(tenant: :unit)
      .where(units: { property_id: current_user.properties.select(:id) })
      .find(params[:maintenance_request_id])

    vendor_ids = Array(params[:vendor_ids])
    created = vendor_ids.filter_map do |vid|
      qr = mr.quote_requests.build(vendor_id: vid)
      qr if qr.save
    end

    if created.any?
      mr.update!(status: :vendor_quote_requested)
      created.each do |qr|
        QuoteRequestNotifier.call(qr)
        qr.update!(status: :sent)
      end
      redirect_to web_manager_maintenance_request_path(mr), notice: "Quote requests sent to #{created.size} vendor(s)."
    else
      redirect_to web_manager_maintenance_request_path(mr), alert: "No quote requests were created. Vendors may have already been requested."
    end
  end

  private

  def require_property_manager!
    redirect_to root_path, alert: "Not authorized." unless current_user&.property_manager?
  end
end
