require "rails_helper"

RSpec.describe "Api::Profile", type: :request do
  let(:manager) { create(:user, :property_manager, name: "Old Name", phone: "555-0000", email: "manager@example.com", password: "password123") }

  describe "PATCH /api/profile" do
    context "updating name and phone" do
      it "updates name and phone" do
        patch "/api/profile", params: { name: "New Name", phone: "555-9999" }, headers: auth_headers(manager)
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["user"]["name"]).to eq("New Name")
        expect(body["user"]["phone"]).to eq("555-9999")
        expect(manager.reload.name).to eq("New Name")
        expect(manager.reload.phone).to eq("555-9999")
      end

      it "updates name only" do
        patch "/api/profile", params: { name: "Just Name" }, headers: auth_headers(manager)
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["user"]["name"]).to eq("Just Name")
      end
    end

    context "updating email" do
      it "updates email" do
        patch "/api/profile", params: { email: "new@example.com" }, headers: auth_headers(manager)
        expect(response).to have_http_status(:ok)
        expect(manager.reload.email).to eq("new@example.com")
      end

      it "rejects a duplicate email" do
        create(:user, email: "taken@example.com")
        patch "/api/profile", params: { email: "taken@example.com" }, headers: auth_headers(manager)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects an invalid email" do
        patch "/api/profile", params: { email: "not-an-email" }, headers: auth_headers(manager)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "updating password" do
      it "updates password with correct current password" do
        patch "/api/profile", params: {
          current_password: "password123",
          password: "newpassword456",
          password_confirmation: "newpassword456"
        }, headers: auth_headers(manager)
        expect(response).to have_http_status(:ok)
        expect(manager.reload.authenticate("newpassword456")).to be_truthy
      end

      it "rejects password change with wrong current password" do
        patch "/api/profile", params: {
          current_password: "wrongpassword",
          password: "newpassword456",
          password_confirmation: "newpassword456"
        }, headers: auth_headers(manager)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("Current password is incorrect")
      end

      it "rejects password change when confirmation doesn't match" do
        patch "/api/profile", params: {
          current_password: "password123",
          password: "newpassword456",
          password_confirmation: "mismatch"
        }, headers: auth_headers(manager)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "requires current_password when changing password" do
        patch "/api/profile", params: {
          password: "newpassword456",
          password_confirmation: "newpassword456"
        }, headers: auth_headers(manager)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("Current password is required")
      end
    end

    it "returns unauthorized without a token" do
      patch "/api/profile", params: { name: "Hacker" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/profile" do
    it "returns the current user's profile" do
      get "/api/profile", headers: auth_headers(manager)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["user"]["email"]).to eq("manager@example.com")
      expect(body["user"]["name"]).to eq("Old Name")
    end

    it "returns unauthorized without a token" do
      get "/api/profile"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
