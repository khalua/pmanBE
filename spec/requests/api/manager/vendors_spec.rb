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
  end
end
