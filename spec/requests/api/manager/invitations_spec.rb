require "rails_helper"

RSpec.describe "Api::Manager::Invitations", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:property) { create(:property, property_manager: manager) }
  let!(:unit) { create(:unit, property: property) }

  describe "POST /api/manager/properties/:property_id/units/:unit_id/invitations" do
    it "creates an invitation" do
      post "/api/manager/properties/#{property.id}/units/#{unit.id}/invitations",
        headers: auth_headers(manager),
        params: { invitation: { tenant_name: "Jane Doe", tenant_email: "jane@example.com" } }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["code"]).to be_present
      expect(body["tenant_name"]).to eq("Jane Doe")
      expect(body["tenant_email"]).to eq("jane@example.com")
      expect(body["unit"]["id"]).to eq(unit.id)
    end

    it "rejects missing tenant_name" do
      post "/api/manager/properties/#{property.id}/units/#{unit.id}/invitations",
        headers: auth_headers(manager),
        params: { invitation: { tenant_email: "jane@example.com" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/manager/properties/:property_id/invitations" do
    let!(:invitation) { create(:tenant_invitation, unit: unit, created_by: manager) }

    it "lists invitations for a property" do
      get "/api/manager/properties/#{property.id}/invitations", headers: auth_headers(manager)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(1)
      expect(body.first["id"]).to eq(invitation.id)
    end
  end

  describe "DELETE /api/manager/invitations/:id" do
    let!(:invitation) { create(:tenant_invitation, unit: unit, created_by: manager) }

    it "revokes an invitation" do
      delete "/api/manager/invitations/#{invitation.id}", headers: auth_headers(manager)

      expect(response).to have_http_status(:ok)
      expect(invitation.reload.active).to be false
    end
  end
end
