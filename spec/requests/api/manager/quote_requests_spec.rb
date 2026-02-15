require "rails_helper"

RSpec.describe "Api::Manager::QuoteRequests", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:mr) { create(:maintenance_request) }

  describe "POST /api/manager/maintenance_requests/:id/quote_requests" do
    it "creates quote requests for given vendors" do
      allow(SmsService).to receive(:send_message)
      vendors = create_list(:vendor, 2)
      post "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
           params: { vendor_ids: vendors.map(&:id) },
           headers: auth_headers(manager)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.size).to eq(2)
      expect(mr.reload.status).to eq("vendor_quote_requested")
    end

    it "sends SMS to each vendor" do
      expect(SmsService).to receive(:send_message).twice
      vendors = create_list(:vendor, 2)
      post "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
           params: { vendor_ids: vendors.map(&:id) },
           headers: auth_headers(manager)
    end

    it "marks quote requests as sent" do
      allow(SmsService).to receive(:send_message)
      vendors = create_list(:vendor, 2)
      post "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
           params: { vendor_ids: vendors.map(&:id) },
           headers: auth_headers(manager)

      statuses = QuoteRequest.where(maintenance_request: mr).pluck(:status)
      expect(statuses).to all(eq("sent"))
    end
  end

  describe "GET /api/manager/maintenance_requests/:id/quote_requests" do
    it "lists quote requests for a maintenance request" do
      create(:quote_request, maintenance_request: mr)
      get "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
          headers: auth_headers(manager)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end
end
