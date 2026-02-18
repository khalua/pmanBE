require "rails_helper"

RSpec.describe "Api::Manager::Units", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:other_manager) { create(:user, :property_manager) }
  let(:property) { create(:property, property_manager: manager) }
  let(:other_property) { create(:property, property_manager: other_manager) }
  let!(:unit) { create(:unit, property: property, identifier: "Unit 1") }

  describe "POST /api/manager/properties/:property_id/units" do
    it "creates a unit" do
      post "/api/manager/properties/#{property.id}/units", headers: auth_headers(manager), params: {
        unit: { identifier: "Unit 2", floor: 2 }
      }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["identifier"]).to eq("Unit 2")
    end

    it "cannot create a unit on another manager's property" do
      post "/api/manager/properties/#{other_property.id}/units", headers: auth_headers(manager), params: {
        unit: { identifier: "Unit X" }
      }
      expect(response).to have_http_status(:not_found)
    end

    it "returns errors for missing identifier" do
      post "/api/manager/properties/#{property.id}/units", headers: auth_headers(manager), params: {
        unit: { identifier: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/manager/properties/:property_id/units/:id" do
    it "updates a unit" do
      patch "/api/manager/properties/#{property.id}/units/#{unit.id}", headers: auth_headers(manager), params: {
        unit: { identifier: "Unit 1 Updated" }
      }
      expect(response).to have_http_status(:ok)
      expect(unit.reload.identifier).to eq("Unit 1 Updated")
    end
  end

  describe "DELETE /api/manager/properties/:property_id/units/:id" do
    it "deletes a unit" do
      delete "/api/manager/properties/#{property.id}/units/#{unit.id}", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      expect(Unit.find_by(id: unit.id)).to be_nil
    end
  end
end
