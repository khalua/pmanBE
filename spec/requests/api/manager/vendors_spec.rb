require "rails_helper"

RSpec.describe "Api::Manager::Vendors", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:tenant) { create(:user) }

  describe "GET /api/manager/vendors" do
    it "returns the manager's vendor pool" do
      vendors = create_list(:vendor, 2)
      vendors.each { |v| create(:property_manager_vendor, user: manager, vendor: v) }
      create(:vendor) # not in pool

      get "/api/manager/vendors", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(2)
    end

    it "returns forbidden for non-managers" do
      get "/api/manager/vendors", headers: auth_headers(tenant)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/manager/vendors" do
    it "adds a vendor to the manager's pool" do
      vendor = create(:vendor)
      post "/api/manager/vendors", params: { vendor_id: vendor.id }, headers: auth_headers(manager)
      expect(response).to have_http_status(:created)
      expect(manager.vendors).to include(vendor)
    end

    it "rejects duplicate vendor" do
      vendor = create(:vendor)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      post "/api/manager/vendors", params: { vendor_id: vendor.id }, headers: auth_headers(manager)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/manager/vendors/:id" do
    it "removes a vendor from the pool" do
      vendor = create(:vendor)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      delete "/api/manager/vendors/#{vendor.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:no_content)
      expect(manager.vendors.reload).not_to include(vendor)
    end
  end

  describe "GET /api/manager/vendors/:id" do
    it "returns vendor details" do
      vendor = create(:vendor)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      get "/api/manager/vendors/#{vendor.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(vendor.id)
      expect(body).to have_key("maintenance_requests")
    end

    it "returns 404 for vendor not in manager pool" do
      vendor = create(:vendor)
      get "/api/manager/vendors/#{vendor.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "vendor selection for maintenance requests" do
    it "only returns the manager's saved vendors, not all vendors" do
      saved_vendor = create(:vendor, name: "Saved Plumber", vendor_type: :plumbing)
      create(:vendor, name: "Other Plumber", vendor_type: :plumbing)
      create(:property_manager_vendor, user: manager, vendor: saved_vendor)

      get "/api/manager/vendors", headers: auth_headers(manager)
      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["name"]).to eq("Saved Plumber")
    end

    it "returns vendors of all types the manager has saved" do
      plumber = create(:vendor, vendor_type: :plumbing)
      electrician = create(:vendor, vendor_type: :electrical)
      create(:property_manager_vendor, user: manager, vendor: plumber)
      create(:property_manager_vendor, user: manager, vendor: electrician)

      get "/api/manager/vendors", headers: auth_headers(manager)
      body = JSON.parse(response.body)
      expect(body.size).to eq(2)
      types = body.map { |v| v["vendor_type"] }
      expect(types).to contain_exactly("plumbing", "electrical")
    end

    it "allows assigning a saved vendor to a maintenance request" do
      vendor = create(:vendor)
      create(:property_manager_vendor, user: manager, vendor: vendor)
      mr = create(:maintenance_request, tenant: tenant)

      post "/api/maintenance_requests/#{mr.id}/assign_vendor",
        params: { vendor_id: vendor.id },
        headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["assigned_vendor"]["id"]).to eq(vendor.id)
      expect(body["status"]).to eq("vendor_quote_requested")
    end

    it "different managers have independent vendor pools" do
      other_manager = create(:user, :property_manager)
      vendor1 = create(:vendor, name: "Manager1 Vendor")
      vendor2 = create(:vendor, name: "Manager2 Vendor")
      create(:property_manager_vendor, user: manager, vendor: vendor1)
      create(:property_manager_vendor, user: other_manager, vendor: vendor2)

      get "/api/manager/vendors", headers: auth_headers(manager)
      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["name"]).to eq("Manager1 Vendor")

      get "/api/manager/vendors", headers: auth_headers(other_manager)
      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["name"]).to eq("Manager2 Vendor")
    end

    it "returns empty array when manager has no saved vendors" do
      get "/api/manager/vendors", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end
end
