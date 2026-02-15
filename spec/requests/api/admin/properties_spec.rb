require "rails_helper"

RSpec.describe "Api::Admin::Properties", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:tenant) { create(:user) }
  let(:manager) { create(:user, :property_manager) }
  let!(:property) { create(:property, property_manager: manager) }

  describe "GET /api/admin/properties" do
    it "returns properties for super_admin" do
      get "/api/admin/properties", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["address"]).to eq(property.address)
    end

    it "returns forbidden for non-admin" do
      get "/api/admin/properties", headers: auth_headers(tenant)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/admin/properties/:id" do
    it "returns property with units" do
      create(:unit, property: property, identifier: "Apt 1A")
      get "/api/admin/properties/#{property.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["units"].size).to eq(1)
      expect(body["units"].first["identifier"]).to eq("Apt 1A")
    end
  end

  describe "POST /api/admin/properties" do
    it "creates a property" do
      post "/api/admin/properties", headers: auth_headers(admin), params: {
        property: { address: "123 New St", property_type: "house", property_manager_id: manager.id }
      }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["address"]).to eq("123 New St")
    end

    it "returns errors for invalid params" do
      post "/api/admin/properties", headers: auth_headers(admin), params: {
        property: { address: "", property_type: "house", property_manager_id: manager.id }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/admin/properties/:id" do
    it "updates a property" do
      patch "/api/admin/properties/#{property.id}", headers: auth_headers(admin), params: {
        property: { name: "Updated Name" }
      }
      expect(response).to have_http_status(:ok)
      expect(property.reload.name).to eq("Updated Name")
    end
  end

  describe "DELETE /api/admin/properties/:id" do
    it "deletes a property" do
      delete "/api/admin/properties/#{property.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(Property.find_by(id: property.id)).to be_nil
    end
  end
end
