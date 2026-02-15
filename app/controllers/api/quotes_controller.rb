class Api::QuotesController < Api::BaseController
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    # Support both Rails-style and vendor portal field names
    req_id = params[:maintenance_request_id] || params[:requestId]
    request = MaintenanceRequest.find(req_id)

    # Map vendor portal fields to model fields
    mapped = {}
    mapped[:vendor_id] = params[:vendor_id] if params[:vendor_id].present?
    mapped[:estimated_cost] = params[:estimated_cost] || params[:cost]
    mapped[:work_description] = params[:work_description] || params[:workDescription]

    if params[:estimated_arrival_time].present?
      mapped[:estimated_arrival_time] = params[:estimated_arrival_time]
    elsif params[:arrivalDate].present?
      time_str = params[:arrivalTime] || "09:00"
      mapped[:estimated_arrival_time] = "#{params[:arrivalDate]} #{time_str}"
    end

    # Auto-assign vendor if one is assigned to the request and none specified
    mapped[:vendor_id] ||= request.assigned_vendor_id

    quote = request.quotes.build(mapped)

    if quote.save
      request.update!(status: :quote_received)
      request.quote_requests.where(vendor_id: quote.vendor_id).update_all(status: QuoteRequest.statuses[:quoted])
      render json: quote_json(quote), status: :created
    else
      render json: { errors: quote.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def approve
    quote = Quote.find(params[:id])
    quote.maintenance_request.update!(status: :quote_accepted)
    render json: { message: "Quote approved", quote: quote_json(quote) }
  end

  def reject
    quote = Quote.find(params[:id])
    quote.maintenance_request.update!(status: :quote_rejected)
    render json: { message: "Quote rejected", quote: quote_json(quote) }
  end

  private

  def quote_params
    params.permit(:vendor_id, :estimated_cost, :estimated_arrival_time, :work_description)
  end

  def quote_json(q)
    {
      id: q.id,
      vendor_id: q.vendor_id,
      maintenance_request_id: q.maintenance_request_id,
      estimated_cost: q.estimated_cost.to_f,
      estimated_arrival_time: q.estimated_arrival_time,
      work_description: q.work_description,
      created_at: q.created_at
    }
  end
end
