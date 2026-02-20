require "rails_helper"

RSpec.describe "Api::Manager::QuoteRequests", type: :request do
  # Wire manager → property → unit → tenant → maintenance_request so scoping works
  let(:manager)  { create(:user, :property_manager) }
  let(:property) { create(:property, property_manager: manager) }
  let(:unit)     { create(:unit, property: property) }
  let(:tenant)   { create(:user, unit: unit) }
  let(:mr)       { create(:maintenance_request, tenant: tenant) }

  describe "POST /api/manager/maintenance_requests/:id/quote_requests" do
    it "creates quote requests for given vendors" do
      vendors = create_list(:vendor, 2)
      post "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
           params: { vendor_ids: vendors.map(&:id) },
           headers: auth_headers(manager)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["quote_requests"].size).to eq(2)
      expect(mr.reload.status).to eq("vendor_quote_requested")
    end

    it "sends SMS to each vendor" do
      vendors = create_list(:vendor, 2)
      expect {
        post "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
             params: { vendor_ids: vendors.map(&:id) },
             headers: auth_headers(manager)
      }.to have_enqueued_mail(VendorNotificationMailer, :sms_simulation).at_least(2).times
    end

    it "marks quote requests as sent" do
      vendors = create_list(:vendor, 2)
      post "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
           params: { vendor_ids: vendors.map(&:id) },
           headers: auth_headers(manager)

      statuses = QuoteRequest.where(maintenance_request: mr).pluck(:status)
      expect(statuses).to all(eq("sent"))
    end

    it "rejects quote requests when status is quote_accepted" do
      mr.update!(status: :quote_accepted)
      vendors = create_list(:vendor, 1)
      post "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
           params: { vendor_ids: vendors.map(&:id) },
           headers: auth_headers(manager)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("Cannot request quotes")
    end

    it "allows additional quote requests when status is vendor_quote_requested" do
      mr.update!(status: :vendor_quote_requested)
      vendors = create_list(:vendor, 1)
      post "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
           params: { vendor_ids: vendors.map(&:id) },
           headers: auth_headers(manager)

      expect(response).to have_http_status(:created)
    end

    it "allows additional quote requests when status is quote_received" do
      mr.update!(status: :quote_received)
      vendors = create_list(:vendor, 1)
      post "/api/manager/maintenance_requests/#{mr.id}/quote_requests",
           params: { vendor_ids: vendors.map(&:id) },
           headers: auth_headers(manager)

      expect(response).to have_http_status(:created)
    end

    it "returns 404 when manager targets another manager's maintenance request" do
      other_chain_mr = create(:maintenance_request)  # unrelated tenant/manager
      vendors = create_list(:vendor, 1)
      post "/api/manager/maintenance_requests/#{other_chain_mr.id}/quote_requests",
           params: { vendor_ids: vendors.map(&:id) },
           headers: auth_headers(manager)

      expect(response).to have_http_status(:not_found)
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

    it "returns 404 when manager tries to list quote requests for another manager's request" do
      other_chain_mr = create(:maintenance_request)
      create(:quote_request, maintenance_request: other_chain_mr)
      get "/api/manager/maintenance_requests/#{other_chain_mr.id}/quote_requests",
          headers: auth_headers(manager)

      expect(response).to have_http_status(:not_found)
    end
  end
end
