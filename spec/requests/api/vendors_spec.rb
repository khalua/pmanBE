require "rails_helper"

RSpec.describe "Api::Vendors", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/vendors" do
    it "returns all vendors" do
      create_list(:vendor, 3)
      get "/api/vendors", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(3)
    end

    it "filters by vendor_type" do
      create(:vendor, vendor_type: :plumbing)
      create(:vendor, vendor_type: :electrical)
      get "/api/vendors", params: { vendor_type: "plumbing" }, headers: auth_headers(user)
      expect(JSON.parse(response.body).size).to eq(1)
    end

    it "filters by availability" do
      create(:vendor, is_available: true)
      create(:vendor, is_available: false)
      get "/api/vendors", params: { available: "true" }, headers: auth_headers(user)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe "GET /api/vendors/:id" do
    it "returns the vendor" do
      vendor = create(:vendor)
      get "/api/vendors/#{vendor.id}", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(vendor.id)
    end
  end
end
