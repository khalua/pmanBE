require "rails_helper"

RSpec.describe "Api::Quotes", type: :request do
  let(:user) { create(:user, :property_manager) }
  let(:vendor) { create(:vendor) }
  let(:mr) { create(:maintenance_request, assigned_vendor: vendor, status: :vendor_quote_requested) }

  describe "POST /api/quotes" do
    it "creates a quote without authentication" do
      post "/api/quotes", params: {
        maintenance_request_id: mr.id,
        vendor_id: vendor.id,
        estimated_cost: 500.0,
        work_description: "Fix the sink"
      }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["estimated_cost"]).to eq(500.0)
      expect(mr.reload.status).to eq("quote_received")
    end

    it "auto-assigns the request's vendor if none specified" do
      post "/api/quotes", params: {
        maintenance_request_id: mr.id,
        estimated_cost: 300.0,
        work_description: "Repair work"
      }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["vendor_id"]).to eq(vendor.id)
    end

    it "returns errors for invalid quote" do
      post "/api/quotes", params: {
        maintenance_request_id: mr.id,
        estimated_cost: -1,
        work_description: ""
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/quotes/:id/approve" do
    it "approves the quote and updates request status" do
      quote = create(:quote, maintenance_request: mr, vendor: vendor)
      post "/api/quotes/#{quote.id}/approve", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(mr.reload.status).to eq("quote_accepted")
    end

    it "assigns the vendor to the maintenance request" do
      other_vendor = create(:vendor)
      quote = create(:quote, maintenance_request: mr, vendor: other_vendor)
      post "/api/quotes/#{quote.id}/approve", headers: auth_headers(user)
      expect(mr.reload.assigned_vendor).to eq(other_vendor)
    end

    it "sends approval notification to vendor and tenant" do
      quote = create(:quote, maintenance_request: mr, vendor: vendor)
      allow(PushNotificationService).to receive(:notify)
      expect {
        post "/api/quotes/#{quote.id}/approve", headers: auth_headers(user)
      }.to have_enqueued_mail(VendorNotificationMailer, :sms_simulation)
    end
  end

  describe "POST /api/quotes/:id/reject" do
    it "rejects the quote and updates request status" do
      quote = create(:quote, maintenance_request: mr, vendor: vendor)
      post "/api/quotes/#{quote.id}/reject", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(mr.reload.status).to eq("quote_rejected")
    end
  end
end
