require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /health" do
    it "returns 200" do
      get "/health"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["status"]).to eq("Server is running")
    end
  end
end
