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

  describe "POST /api/maintenance_requests/:id/close" do
    it "closes the request with status 'closed' and creates a note" do
      mr = create(:maintenance_request, tenant: tenant, status: :submitted)
      post "/api/maintenance_requests/#{mr.id}/close",
        params: { note: "This is not something we can help with." },
        headers: auth_headers(pm)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("closed")
      expect(mr.reload.notes.last.content).to eq("This is not something we can help with.")
      expect(mr.notes.last.user).to eq(pm)
    end

    it "requires a note" do
      mr = create(:maintenance_request, tenant: tenant)
      post "/api/maintenance_requests/#{mr.id}/close",
        params: { note: "" },
        headers: auth_headers(pm)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects tenants from closing requests" do
      mr = create(:maintenance_request, tenant: tenant)
      post "/api/maintenance_requests/#{mr.id}/close",
        params: { note: "closing" },
        headers: auth_headers(tenant)
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot close an already completed request" do
      mr = create(:maintenance_request, tenant: tenant, status: :completed)
      post "/api/maintenance_requests/#{mr.id}/close",
        params: { note: "closing again" },
        headers: auth_headers(pm)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "cannot close an already closed request" do
      mr = create(:maintenance_request, tenant: tenant, status: :closed)
      post "/api/maintenance_requests/#{mr.id}/close",
        params: { note: "closing again" },
        headers: auth_headers(pm)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/maintenance_requests/:id/mark_complete" do
    it "allows a tenant to mark their own request as complete" do
      mr = create(:maintenance_request, tenant: tenant, status: :in_progress)
      post "/api/maintenance_requests/#{mr.id}/mark_complete",
        headers: auth_headers(tenant)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("completed")
    end

    it "allows a manager to mark a request as complete" do
      mr = create(:maintenance_request, tenant: tenant, status: :in_progress)
      post "/api/maintenance_requests/#{mr.id}/mark_complete",
        headers: auth_headers(pm)
      expect(response).to have_http_status(:ok)
      expect(mr.reload.status).to eq("completed")
    end

    it "prevents a tenant from marking another tenant's request complete" do
      other_tenant = create(:user)
      mr = create(:maintenance_request, tenant: other_tenant, status: :in_progress)
      post "/api/maintenance_requests/#{mr.id}/mark_complete",
        headers: auth_headers(tenant)
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot mark an already completed request complete" do
      mr = create(:maintenance_request, tenant: tenant, status: :completed)
      post "/api/maintenance_requests/#{mr.id}/mark_complete",
        headers: auth_headers(pm)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "cannot mark a closed request complete" do
      mr = create(:maintenance_request, tenant: tenant, status: :closed)
      post "/api/maintenance_requests/#{mr.id}/mark_complete",
        headers: auth_headers(pm)
      expect(response).to have_http_status(:unprocessable_entity)
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
