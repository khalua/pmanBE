require "rails_helper"

RSpec.describe "Api::Admin::Units", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:manager) { create(:user, :property_manager) }
  let(:property) { create(:property, property_manager: manager) }
  let!(:unit) { create(:unit, property: property, identifier: "Apt 2B") }

  describe "POST /api/admin/properties/:property_id/units" do
    it "creates a unit" do
      post "/api/admin/properties/#{property.id}/units", headers: auth_headers(admin), params: {
        unit: { identifier: "Apt 3C", floor: 3 }
      }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["identifier"]).to eq("Apt 3C")
    end

    it "returns errors for missing identifier" do
      post "/api/admin/properties/#{property.id}/units", headers: auth_headers(admin), params: {
        unit: { identifier: "", floor: 1 }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/admin/properties/:property_id/units/:id" do
    it "updates a unit" do
      patch "/api/admin/properties/#{property.id}/units/#{unit.id}", headers: auth_headers(admin), params: {
        unit: { identifier: "Apt 2B-Updated" }
      }
      expect(response).to have_http_status(:ok)
      expect(unit.reload.identifier).to eq("Apt 2B-Updated")
    end

    it "assigns a tenant to a unit" do
      tenant = create(:user)
      patch "/api/admin/properties/#{property.id}/units/#{unit.id}", headers: auth_headers(admin), params: {
        unit: { tenant_id: tenant.id }
      }
      expect(response).to have_http_status(:ok)
      expect(tenant.reload.unit_id).to eq(unit.id)
      body = JSON.parse(response.body)
      expect(body["tenant"]["id"]).to eq(tenant.id)
    end

    it "removes a tenant from a unit" do
      tenant = create(:user, unit: unit)
      patch "/api/admin/properties/#{property.id}/units/#{unit.id}", headers: auth_headers(admin), params: {
        unit: { tenant_id: "" }
      }
      expect(response).to have_http_status(:ok)
      expect(tenant.reload.unit_id).to be_nil
    end
  end

  describe "DELETE /api/admin/properties/:property_id/units/:id" do
    it "deletes a unit" do
      delete "/api/admin/properties/#{property.id}/units/#{unit.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(Unit.find_by(id: unit.id)).to be_nil
    end
  end
end
