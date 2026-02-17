require "rails_helper"

RSpec.describe "Web::Manager::Invitations", type: :request do
  let(:manager) { create(:user, :property_manager) }
  let(:property) { create(:property, property_manager: manager) }
  let!(:unit) { create(:unit, property: property, identifier: "Apt 1A") }

  def log_in(user)
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /web/manager/properties/:property_id/invitations" do
    it "lists invitations for the property" do
      invitation = create(:tenant_invitation, unit: unit, created_by: manager, tenant_name: "Jane Doe")
      log_in(manager)

      get web_manager_property_invitations_path(property)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jane Doe")
      expect(response.body).to include(invitation.code)
      expect(response.body).to include("Apt 1A")
    end

    it "shows the create invitation form" do
      log_in(manager)

      get web_manager_property_invitations_path(property)
      expect(response.body).to include("Create New Invitation")
      expect(response.body).to include("Apt 1A")
    end

    it "redirects unauthenticated users" do
      get web_manager_property_invitations_path(property)
      expect(response).to redirect_to(login_path)
    end

    it "redirects non-managers" do
      log_in(create(:user))
      get web_manager_property_invitations_path(property)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /web/manager/properties/:property_id/invitations" do
    it "creates an invitation" do
      log_in(manager)

      expect {
        post web_manager_property_invitations_path(property), params: {
          invitation: { unit_id: unit.id, tenant_name: "John Smith", tenant_email: "john@example.com" }
        }
      }.to change { TenantInvitation.count }.by(1)

      expect(response).to redirect_to(web_manager_property_invitations_path(property))
      follow_redirect!
      expect(response.body).to include("Invitation created")
    end

    it "shows errors for invalid params" do
      log_in(manager)

      post web_manager_property_invitations_path(property), params: {
        invitation: { unit_id: unit.id, tenant_name: "", tenant_email: "john@example.com" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /web/manager/properties/:property_id/invitations/:id/revoke" do
    it "revokes an invitation" do
      invitation = create(:tenant_invitation, unit: unit, created_by: manager)
      log_in(manager)

      post revoke_web_manager_property_invitation_path(property, invitation)

      expect(response).to redirect_to(web_manager_property_invitations_path(property))
      expect(invitation.reload.active).to be false
    end
  end
end
