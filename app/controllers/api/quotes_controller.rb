class Api::QuotesController < Api::BaseController
  def create
    request = MaintenanceRequest.find(params[:maintenance_request_id])
    quote = request.quotes.build(quote_params)

    if quote.save
      request.update!(status: :quote_received)
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
