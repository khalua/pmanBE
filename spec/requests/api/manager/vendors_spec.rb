require "rails_helper"

RSpec.describe "Api::Manager::Vendors", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:tenant) { create(:user) }

  def vendor_params(overrides = {})
    attributes_for(:vendor).merge(overrides).slice(
      :name, :vendor_type, :contact_name, :cell_phone, :phone_number,
      :email, :address, :website, :notes, :is_available
    )
  end

  describe "GET /api/manager/vendors" do
    it "returns the manager's vendor pool" do
      vendors = create_list(:vendor, 2, owner_user_id: manager.id)
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
    it "creates a vendor and adds it to the manager's pool" do
      expect {
        post "/api/manager/vendors", params: { vendor: vendor_params }, headers: auth_headers(manager)
      }.to change { manager.vendors.count }.by(1)
        .and change { Vendor.count }.by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to be_present
      expect(body["is_active"]).to be true
    end

    it "sets owner to manager" do
      post "/api/manager/vendors", params: { vendor: vendor_params }, headers: auth_headers(manager)
      expect(Vendor.last.owner_user_id).to eq(manager.id)
    end

    it "returns errors on invalid params" do
      post "/api/manager/vendors", params: { vendor: vendor_params(cell_phone: "") }, headers: auth_headers(manager)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key("errors")
    end
  end

  describe "PATCH /api/manager/vendors/:id" do
    it "updates an owned vendor" do
      vendor = create(:vendor, owner_user_id: manager.id)
      create(:property_manager_vendor, user: manager, vendor: vendor)

      patch "/api/manager/vendors/#{vendor.id}", params: { vendor: { name: "New Name" } }, headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      expect(vendor.reload.name).to eq("New Name")
    end
  end

  describe "PATCH /api/manager/vendors/:id/toggle_active" do
    it "toggles is_active on the join record" do
      vendor = create(:vendor, owner_user_id: manager.id)
      pmv = create(:property_manager_vendor, user: manager, vendor: vendor, is_active: true)

      patch "/api/manager/vendors/#{vendor.id}/toggle_active", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      expect(pmv.reload.is_active).to be false
      expect(JSON.parse(response.body)["is_active"]).to be false
    end
  end

  describe "DELETE /api/manager/vendors/:id" do
    it "removes owned vendor from pool and destroys it" do
      vendor = create(:vendor, owner_user_id: manager.id)
      create(:property_manager_vendor, user: manager, vendor: vendor)

      expect {
        delete "/api/manager/vendors/#{vendor.id}", headers: auth_headers(manager)
      }.to change { Vendor.count }.by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/manager/vendors/:id" do
    it "returns vendor details with stats" do
      vendor = create(:vendor, owner_user_id: manager.id)
      create(:property_manager_vendor, user: manager, vendor: vendor)

      get "/api/manager/vendors/#{vendor.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(vendor.id)
      expect(body).to have_key("maintenance_requests")
      expect(body).to have_key("stats")
      expect(body["stats"]).to include("quotes_received", "requests_fulfilled", "average_rating")
    end

    it "returns 404 for vendor not in manager pool" do
      vendor = create(:vendor)
      get "/api/manager/vendors/#{vendor.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "different managers have independent vendor pools" do
    it "isolates vendors per manager" do
      other_manager = create(:user, :property_manager)
      v1 = create(:vendor, name: "Manager1 Vendor", owner_user_id: manager.id)
      v2 = create(:vendor, name: "Manager2 Vendor", owner_user_id: other_manager.id)
      create(:property_manager_vendor, user: manager, vendor: v1)
      create(:property_manager_vendor, user: other_manager, vendor: v2)

      get "/api/manager/vendors", headers: auth_headers(manager)
      expect(JSON.parse(response.body).map { |v| v["name"] }).to eq([ "Manager1 Vendor" ])
    end
  end
end
