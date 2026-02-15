require "rails_helper"

RSpec.describe "Api::Auth", type: :request do
  describe "POST /api/register" do
    it "creates a user and returns a token" do
      post "/api/register", params: { email: "test@example.com", password: "password123", name: "Test User" }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["user"]["email"]).to eq("test@example.com")
    end

    it "returns errors for invalid params" do
      post "/api/register", params: { email: "", password: "password123", name: "" }
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to be_present
    end

    it "rejects duplicate emails" do
      create(:user, email: "dup@example.com")
      post "/api/register", params: { email: "dup@example.com", password: "password123", name: "Dup" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/login" do
    let!(:user) { create(:user, email: "login@example.com", password: "password123") }

    it "returns a token on valid credentials" do
      post "/api/login", params: { email: "login@example.com", password: "password123" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["token"]).to be_present
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
