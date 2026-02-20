require "rails_helper"

RSpec.describe "Api::MaintenanceRequests", type: :request do
  # ----- shared helpers -----
  # Build a fully-linked manager → property → unit → tenant chain.
  # Returns { manager:, property:, unit:, tenant:, request: }
  def create_managed_chain(manager: nil)
    manager  ||= create(:user, :property_manager)
    property   = create(:property, property_manager: manager)
    unit       = create(:unit, property: property)
    tenant     = create(:user, unit: unit)
    mr         = create(:maintenance_request, tenant: tenant)
    { manager: manager, property: property, unit: unit, tenant: tenant, request: mr }
  end

  # ============================================================
  # GET /api/maintenance_requests  (INDEX)
  # ============================================================
  describe "GET /api/maintenance_requests" do
    context "as a tenant" do
      it "returns only the tenant's own requests" do
        chain = create_managed_chain
        create(:maintenance_request)   # belongs to a completely unrelated tenant

        get "/api/maintenance_requests", headers: auth_headers(chain[:tenant])

        expect(response).to have_http_status(:ok)
        ids = JSON.parse(response.body).map { |r| r["id"] }
        expect(ids).to eq([ chain[:request].id ])
      end
    end

    context "as a property manager" do
      it "returns only requests belonging to tenants in their properties" do
        chain = create_managed_chain

        # A second, completely independent manager/property/tenant/request
        other_chain = create_managed_chain

        get "/api/maintenance_requests", headers: auth_headers(chain[:manager])

        expect(response).to have_http_status(:ok)
        ids = JSON.parse(response.body).map { |r| r["id"] }

        expect(ids).to include(chain[:request].id)
        expect(ids).not_to include(other_chain[:request].id)
      end

      it "returns requests from all of their own properties" do
        manager   = create(:user, :property_manager)
        property1 = create(:property, property_manager: manager)
        property2 = create(:property, property_manager: manager)
        unit1     = create(:unit, property: property1)
        unit2     = create(:unit, property: property2)
        tenant1   = create(:user, unit: unit1)
        tenant2   = create(:user, unit: unit2)
        mr1       = create(:maintenance_request, tenant: tenant1)
        mr2       = create(:maintenance_request, tenant: tenant2)

        # Unrelated manager's request — must NOT appear
        other_chain = create_managed_chain

        get "/api/maintenance_requests", headers: auth_headers(manager)

        ids = JSON.parse(response.body).map { |r| r["id"] }
        expect(ids).to match_array([ mr1.id, mr2.id ])
        expect(ids).not_to include(other_chain[:request].id)
      end

      it "returns an empty list when manager has no properties" do
        manager = create(:user, :property_manager)
        create_managed_chain   # unrelated manager/tenant

        get "/api/maintenance_requests", headers: auth_headers(manager)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to be_empty
      end
    end

    context "as a super_admin" do
      it "returns all requests" do
        admin = create(:user, :super_admin)
        create_managed_chain
        create_managed_chain

        get "/api/maintenance_requests", headers: auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(MaintenanceRequest.count)
      end
    end

    it "returns unauthorized without auth" do
      get "/api/maintenance_requests"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ============================================================
  # GET /api/maintenance_requests/:id  (SHOW)
  # ============================================================
  describe "GET /api/maintenance_requests/:id" do
    it "allows a tenant to view their own request" do
      chain = create_managed_chain
      get "/api/maintenance_requests/#{chain[:request].id}", headers: auth_headers(chain[:tenant])
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(chain[:request].id)
    end

    it "allows a manager to view a request in their property" do
      chain = create_managed_chain
      get "/api/maintenance_requests/#{chain[:request].id}", headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:ok)
    end

    it "prevents a manager from viewing a request outside their properties" do
      chain       = create_managed_chain
      other_chain = create_managed_chain

      get "/api/maintenance_requests/#{other_chain[:request].id}", headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:not_found)
    end

    it "prevents a tenant from viewing another tenant's request" do
      chain       = create_managed_chain
      other_chain = create_managed_chain

      get "/api/maintenance_requests/#{other_chain[:request].id}", headers: auth_headers(chain[:tenant])
      expect(response).to have_http_status(:not_found)
    end
  end

  # ============================================================
  # POST /api/maintenance_requests  (CREATE)
  # ============================================================
  describe "POST /api/maintenance_requests" do
    let(:tenant) { create(:user) }

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

  # ============================================================
  # PATCH /api/maintenance_requests/:id  (UPDATE)
  # ============================================================
  describe "PATCH /api/maintenance_requests/:id" do
    it "allows a manager to update status on their request" do
      chain = create_managed_chain
      patch "/api/maintenance_requests/#{chain[:request].id}",
        params: { status: "in_progress" },
        headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("in_progress")
    end
  end

  # ============================================================
  # POST /api/maintenance_requests/:id/close
  # ============================================================
  describe "POST /api/maintenance_requests/:id/close" do
    it "closes the request with a note" do
      chain = create_managed_chain
      post "/api/maintenance_requests/#{chain[:request].id}/close",
        params: { note: "Not covered by policy." },
        headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("closed")
      expect(chain[:request].reload.notes.last.content).to eq("Not covered by policy.")
    end

    it "requires a note" do
      chain = create_managed_chain
      post "/api/maintenance_requests/#{chain[:request].id}/close",
        params: { note: "" },
        headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects tenants from closing requests" do
      chain = create_managed_chain
      post "/api/maintenance_requests/#{chain[:request].id}/close",
        params: { note: "closing" },
        headers: auth_headers(chain[:tenant])
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot close an already completed request" do
      chain = create_managed_chain
      chain[:request].update!(status: :completed)
      post "/api/maintenance_requests/#{chain[:request].id}/close",
        params: { note: "closing again" },
        headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "cannot close an already closed request" do
      chain = create_managed_chain
      chain[:request].update!(status: :closed)
      post "/api/maintenance_requests/#{chain[:request].id}/close",
        params: { note: "closing again" },
        headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ============================================================
  # POST /api/maintenance_requests/:id/mark_complete
  # ============================================================
  describe "POST /api/maintenance_requests/:id/mark_complete" do
    it "allows a tenant to mark their own request as complete" do
      chain = create_managed_chain
      chain[:request].update!(status: :in_progress)
      post "/api/maintenance_requests/#{chain[:request].id}/mark_complete",
        headers: auth_headers(chain[:tenant])
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("completed")
    end

    it "allows a manager to mark a request in their property as complete" do
      chain = create_managed_chain
      chain[:request].update!(status: :in_progress)
      post "/api/maintenance_requests/#{chain[:request].id}/mark_complete",
        headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:ok)
      expect(chain[:request].reload.status).to eq("completed")
    end

    it "prevents a tenant from marking another tenant's request complete" do
      chain       = create_managed_chain
      other_chain = create_managed_chain
      other_chain[:request].update!(status: :in_progress)

      post "/api/maintenance_requests/#{other_chain[:request].id}/mark_complete",
        headers: auth_headers(chain[:tenant])
      expect(response).to have_http_status(:not_found)
    end

    it "cannot mark an already completed request complete" do
      chain = create_managed_chain
      chain[:request].update!(status: :completed)
      post "/api/maintenance_requests/#{chain[:request].id}/mark_complete",
        headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "cannot mark a closed request complete" do
      chain = create_managed_chain
      chain[:request].update!(status: :closed)
      post "/api/maintenance_requests/#{chain[:request].id}/mark_complete",
        headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ============================================================
  # POST /api/maintenance_requests/:id/assign_vendor
  # ============================================================
  describe "POST /api/maintenance_requests/:id/assign_vendor" do
    it "assigns a vendor and updates status" do
      chain  = create_managed_chain
      vendor = create(:vendor)
      post "/api/maintenance_requests/#{chain[:request].id}/assign_vendor",
        params: { vendor_id: vendor.id },
        headers: auth_headers(chain[:manager])
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["assigned_vendor"]["id"]).to eq(vendor.id)
      expect(body["status"]).to eq("vendor_quote_requested")
    end
  end
end
