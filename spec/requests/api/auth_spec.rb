require "rails_helper"

RSpec.describe "Api::Auth", type: :request do
  describe "POST /api/register" do
    context "tenant registration" do
      let(:unit) { create(:unit) }
      let(:manager) { create(:user, :property_manager) }
      let!(:invitation) { create(:tenant_invitation, unit: unit, created_by: manager, tenant_email: "test@example.com") }

      it "creates a tenant with a valid invite code" do
        post "/api/register", params: {
          email: "test@example.com", password: "password123",
          name: "Test User", mobile_phone: "555-1234", invite_code: invitation.code
        }
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["token"]).to be_present
        expect(body["user"]["email"]).to eq("test@example.com")
        expect(body["phone_verification_required"]).to be true
        expect(User.last.unit_id).to eq(unit.id)
        expect(invitation.reload.claimed_by_id).to eq(User.last.id)
      end

      it "rejects registration without an invite code" do
        post "/api/register", params: {
          email: "test@example.com", password: "password123",
          name: "Test User", mobile_phone: "555-1234"
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects registration with wrong email for invite" do
        post "/api/register", params: {
          email: "wrong@example.com", password: "password123",
          name: "Test User", mobile_phone: "555-1234", invite_code: invitation.code
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("Email does not match")
      end

      it "rejects registration with expired invite code" do
        invitation.update!(expires_at: 1.day.ago)
        post "/api/register", params: {
          email: "test@example.com", password: "password123",
          name: "Test User", mobile_phone: "555-1234", invite_code: invitation.code
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("Invalid or expired")
      end

      it "rejects registration with already-claimed invite code" do
        invitation.update!(claimed_by: create(:user))
        post "/api/register", params: {
          email: "test@example.com", password: "password123",
          name: "Test User", mobile_phone: "555-1234", invite_code: invitation.code
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "property manager registration" do
      it "creates a property manager without invite code" do
        post "/api/register", params: {
          email: "manager@example.com", password: "password123",
          name: "Manager User", role: "property_manager"
        }
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["user"]["role"]).to eq("property_manager")
      end
    end

    it "rejects duplicate emails" do
      create(:user, email: "dup@example.com")
      post "/api/register", params: { email: "dup@example.com", password: "password123", name: "Dup", role: "property_manager" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/login" do
    let!(:user) { create(:user, :property_manager, email: "login@example.com", password: "password123") }

    it "returns a token on valid credentials" do
      post "/api/login", params: { email: "login@example.com", password: "password123" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["token"]).to be_present
    end

    it "returns phone_verification_required for unverified tenant" do
      tenant = create(:user, :unverified, email: "tenant@example.com", password: "password123")
      post "/api/login", params: { email: "tenant@example.com", password: "password123" }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["phone_verification_required"]).to be true
      expect(body["token"]).to be_present
    end

    it "returns unauthorized on wrong password" do
      post "/api/login", params: { email: "login@example.com", password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized for nonexistent email" do
      post "/api/login", params: { email: "nobody@example.com", password: "password123" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/me" do
    it "returns user info when authenticated" do
      user = create(:user)
      get "/api/me", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["user"]["id"]).to eq(user.id)
    end

    it "returns unauthorized without a token" do
      get "/api/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
