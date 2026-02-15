require "rails_helper"

RSpec.describe "Api::MaintenanceRequests", type: :request do
  let(:tenant) { create(:user) }
  let(:pm) { create(:user, :property_manager) }

  describe "GET /api/maintenance_requests" do
    it "returns only tenant's own requests for a tenant" do
      create(:maintenance_request, tenant: tenant)
      create(:maintenance_request) # belongs to another tenant

      get "/api/maintenance_requests", headers: auth_headers(tenant)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end

    it "returns all requests for a property manager" do
      create(:maintenance_request, tenant: tenant)
      create(:maintenance_request)

      get "/api/maintenance_requests", headers: auth_headers(pm)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it "returns unauthorized without auth" do
      get "/api/maintenance_requests"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/maintenance_requests/:id" do
    it "returns the request" do
      mr = create(:maintenance_request, tenant: tenant)
      get "/api/maintenance_requests/#{mr.id}", headers: auth_headers(tenant)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(mr.id)
    end
  end

  describe "POST /api/maintenance_requests" do
    it "creates a maintenance request" do
      post "/api/maintenance_requests",
        params: { issue_type: "plumbing", location: "Unit 1", severity: "urgent" },
        headers: auth_headers(tenant)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["issue_type"]).to eq("plumbing")
      expect(body["severity"]).to eq("urgent")
    end

    it "returns errors for missing fields" do
      post "/api/maintenance_requests",
        params: { issue_type: "" },
        headers: auth_headers(tenant)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/maintenance_requests/:id" do
    it "updates the status" do
      mr = create(:maintenance_request, tenant: tenant)
      patch "/api/maintenance_requests/#{mr.id}",
        params: { status: "in_progress" },
        headers: auth_headers(pm)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("in_progress")
    end
  end

  describe "POST /api/maintenance_requests/:id/assign_vendor" do
    it "assigns a vendor and updates status" do
      mr = create(:maintenance_request, tenant: tenant)
      vendor = create(:vendor)
      post "/api/maintenance_requests/#{mr.id}/assign_vendor",
        params: { vendor_id: vendor.id },
        headers: auth_headers(pm)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["assigned_vendor"]["id"]).to eq(vendor.id)
      expect(body["status"]).to eq("vendor_quote_requested")
    end
  end
end
