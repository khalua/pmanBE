require "rails_helper"

RSpec.describe "VendorPortal", type: :request do
  let(:vendor) { create(:vendor) }
  let(:mr) { create(:maintenance_request) }
  let(:quote_request) { create(:quote_request, maintenance_request: mr, vendor: vendor, status: :sent) }

  describe "GET /quote" do
    it "renders the portal with a valid token" do
      get "/quote", params: { token: quote_request.token }
      expect(response).to have_http_status(:ok)
    end

    it "rejects requests without a token" do
      get "/quote"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include("valid token is required")
    end

    it "rejects requests with only an id parameter (no token)" do
      get "/quote", params: { id: mr.id }
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 404 for an invalid token" do
      get "/quote", params: { token: "nonexistent-token" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
