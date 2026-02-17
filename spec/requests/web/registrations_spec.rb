require "rails_helper"

RSpec.describe "Web::Registrations", type: :request do
  describe "GET /register" do
    context "without invite code" do
      it "redirects to login with a message" do
        get register_path
        expect(response).to redirect_to(login_path)
        follow_redirect!
        expect(response.body).to include("invitation link")
      end
    end

    context "with an invalid invite_code" do
      it "redirects to login with a message" do
        get register_path(invite_code: "BADCODE")
        expect(response).to redirect_to(login_path)
      end
    end

    context "with a valid invite_code" do
      let(:manager) { create(:user, :property_manager) }
      let(:property) { create(:property, property_manager: manager) }
      let(:unit) { create(:unit, property: property) }
      let(:invitation) { create(:tenant_invitation, unit: unit, created_by: manager) }

      it "renders the invitation registration form" do
        get register_path(invite_code: invitation.code)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Welcome to Prompt!")
        expect(response.body).to include(invitation.tenant_name)
        expect(response.body).to include(invitation.tenant_email)
        expect(response.body).to include(unit.identifier)
      end

      it "does not show Google OAuth" do
        get register_path(invite_code: invitation.code)
        expect(response.body).not_to include("Sign up with Google")
      end
    end
  end

  describe "POST /register" do
    context "without invite code" do
      it "rejects registration" do
        expect {
          post register_path, params: { name: "Jane", email: "jane@example.com", password: "password123", password_confirmation: "password123" }
        }.not_to change(User, :count)

        expect(response).to redirect_to(login_path)
      end
    end

    context "with a valid invite code" do
      let(:manager) { create(:user, :property_manager) }
      let(:property) { create(:property, property_manager: manager) }
      let(:unit) { create(:unit, property: property) }
      let(:invitation) { create(:tenant_invitation, unit: unit, created_by: manager, tenant_email: "tenant@example.com") }

      it "creates a tenant assigned to the unit" do
        invitation # eagerly create
        expect {
          post register_path, params: { invite_code: invitation.code, name: "Bob Tenant", mobile_phone: "5551234567", password: "password123", password_confirmation: "password123" }
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.tenant?).to be true
        expect(user.unit).to eq(unit)
        expect(user.email).to eq("tenant@example.com")
        expect(user.move_in_date).to eq(Date.current)
        expect(invitation.reload.claimed_by).to eq(user)
        expect(response).to redirect_to(web_tenant_dashboard_path)
      end

      it "rejects an expired invitation" do
        invitation.update!(expires_at: 1.day.ago)
        post register_path, params: { invite_code: invitation.code, name: "Bob", password: "password123", password_confirmation: "password123" }
        expect(response).to redirect_to(login_path)
      end

      it "rejects a claimed invitation" do
        invitation.update!(claimed_by: create(:user, :tenant), active: false)
        post register_path, params: { invite_code: invitation.code, name: "Bob", password: "password123", password_confirmation: "password123" }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
