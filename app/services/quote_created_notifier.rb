class QuoteCreatedNotifier
  def self.call(quote)
    new(quote).call
  end

  def initialize(quote)
    @quote = quote
    @mr = quote.maintenance_request
  end

  def call
    manager = @mr.tenant.unit&.property&.property_manager
    return unless manager

    PushNotificationService.notify(
      user: manager,
      title: "Quote Received",
      body: "New quote for #{@mr.issue_type}: $#{'%.2f' % @quote.estimated_cost}",
      data: { maintenance_request_id: @mr.id.to_s, type: "quote_received" }
    )
  end
end
