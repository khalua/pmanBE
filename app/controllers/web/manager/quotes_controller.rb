class Web::Manager::QuotesController < WebController
  before_action :authenticate_user!
  before_action :require_property_manager!
  before_action :set_quote

  def approve
    @quote.maintenance_request.update!(status: :quote_accepted, assigned_vendor: @quote.vendor)
    redirect_to select_message_web_manager_quote_path(@quote)
  end

  def select_message
    # @quote is already set by before_action
    # Renders a view with two buttons for message selection
  end

  def send_approval_message
    message_type = params[:message_type]

    unless %w[contact_tenant manager_will_contact].include?(message_type)
      redirect_to web_manager_maintenance_request_path(@quote.maintenance_request),
                  alert: "Invalid message type."
      return
    end

    QuoteApprovalNotifier.call(@quote, message_type: message_type)

    redirect_to web_manager_maintenance_request_path(@quote.maintenance_request),
                notice: "Quote approved and vendor notified."
  end

  def reject
    ActiveRecord::Base.transaction do
      @quote.maintenance_request.update!(status: :quote_rejected)

      # Update the corresponding QuoteRequest status
      if @quote.vendor_id.present?
        @quote.maintenance_request.quote_requests
          .where(vendor_id: @quote.vendor_id)
          .update_all(status: QuoteRequest.statuses[:rejected])
      end
    end

    # Send rejection notification (non-blocking)
    QuoteRejectionNotifier.call(@quote)

    redirect_to web_manager_maintenance_request_path(@quote.maintenance_request),
                notice: "Quote rejected and vendor notified."
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
