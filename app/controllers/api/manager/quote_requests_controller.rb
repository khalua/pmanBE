class Api::Manager::QuoteRequestsController < Api::Manager::BaseController
  def index
    mr = find_maintenance_request
    quote_requests = mr.quote_requests.includes(:vendor, :maintenance_request)

    render json: quote_requests.map { |qr| quote_request_json(qr) }
  end

  def create
    mr = find_maintenance_request
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
    end

    render json: created.map { |qr| quote_request_json(qr) }, status: :created
  end

  private

  def find_maintenance_request
    MaintenanceRequest.find(params[:maintenance_request_id])
  end

  def quote_request_json(qr)
    {
      id: qr.id,
      maintenance_request_id: qr.maintenance_request_id,
      vendor_id: qr.vendor_id,
      vendor_name: qr.vendor.name,
      status: qr.status,
      created_at: qr.created_at
    }
  end
end
