require "rails_helper"

RSpec.describe "Api::PhoneVerifications", type: :request do
  let(:tenant) { create(:user, :unverified) }

  describe "POST /api/phone/verify/send" do
    it "creates a verification and returns the demo code" do
      post "/api/phone/verify/send", headers: auth_headers(tenant)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["demo_code"]).to be_present
      expect(body["demo_code"].length).to eq(6)
    end
  end

  describe "POST /api/phone/verify/confirm" do
    it "verifies with correct code" do
      verification = tenant.phone_verifications.create!(
        phone_number: tenant.mobile_phone,
        code: "123456",
        expires_at: 10.minutes.from_now
      )

      post "/api/phone/verify/confirm", headers: auth_headers(tenant), params: { code: "123456" }

      expect(response).to have_http_status(:ok)
      expect(tenant.reload.phone_verified).to be true
      expect(verification.reload.verified_at).to be_present
    end

    it "rejects wrong code" do
      tenant.phone_verifications.create!(
        phone_number: tenant.mobile_phone,
        code: "123456",
        expires_at: 10.minutes.from_now
      )

      post "/api/phone/verify/confirm", headers: auth_headers(tenant), params: { code: "000000" }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects expired code" do
      tenant.phone_verifications.create!(
        phone_number: tenant.mobile_phone,
        code: "123456",
        expires_at: 1.minute.ago
      )

      post "/api/phone/verify/confirm", headers: auth_headers(tenant), params: { code: "123456" }

      expect(response).to have_http_status(:not_found)
    end
  end
end
