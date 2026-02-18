require "rails_helper"

RSpec.describe "Api::Manager::Properties", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:other_manager) { create(:user, :property_manager) }
  let!(:property) { create(:property, property_manager: manager) }
  let!(:other_property) { create(:property, property_manager: other_manager) }

  describe "GET /api/manager/properties" do
    it "returns only the manager's own properties" do
      get "/api/manager/properties", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |p| p["id"] }
      expect(ids).to include(property.id)
      expect(ids).not_to include(other_property.id)
    end

    it "returns forbidden for tenants" do
      tenant = create(:user)
      get "/api/manager/properties", headers: auth_headers(tenant)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/manager/properties/:id" do
    it "returns property with units" do
      unit = create(:unit, property: property)
      get "/api/manager/properties/#{property.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(property.id)
      expect(body["units"]).to be_an(Array)
    end

    it "returns not found for another manager's property" do
      get "/api/manager/properties/#{other_property.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/manager/properties" do
    it "creates a property assigned to the current manager" do
      post "/api/manager/properties", headers: auth_headers(manager), params: {
        property: { address: "456 Oak Ave", name: "Oak House", property_type: "house" }
      }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["address"]).to eq("456 Oak Ave")
      expect(Property.last.property_manager_id).to eq(manager.id)
    end

    it "returns errors for missing address" do
      post "/api/manager/properties", headers: auth_headers(manager), params: {
        property: { address: "", property_type: "house" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/manager/properties/:id" do
    it "updates the property" do
      patch "/api/manager/properties/#{property.id}", headers: auth_headers(manager), params: {
        property: { name: "Updated Name" }
      }
      expect(response).to have_http_status(:ok)
      expect(property.reload.name).to eq("Updated Name")
    end

    it "cannot update another manager's property" do
      patch "/api/manager/properties/#{other_property.id}", headers: auth_headers(manager), params: {
        property: { name: "Hacked" }
      }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/manager/properties/:id" do
    it "deletes the property" do
      delete "/api/manager/properties/#{property.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      expect(Property.find_by(id: property.id)).to be_nil
    end

    it "cannot delete another manager's property" do
      delete "/api/manager/properties/#{other_property.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:not_found)
    end
  end
end
