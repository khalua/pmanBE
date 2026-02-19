require "rails_helper"

RSpec.describe "POST /api/maintenance_requests/:id/rate_vendor", type: :request do
  let(:tenant) { create(:user) }
  let(:vendor) { create(:vendor) }
  let(:maintenance_request) { create(:maintenance_request, tenant: tenant, assigned_vendor: vendor) }

  it "allows tenant to rate the vendor on their completed request" do
    post rate_vendor_api_maintenance_request_path(maintenance_request),
      params: { stars: 5, comment: "Excellent service!" },
      headers: auth_headers(tenant)

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["stars"]).to eq(5)
    expect(body["comment"]).to eq("Excellent service!")
    expect(VendorRating.count).to eq(1)
  end

  it "updates an existing rating instead of creating a duplicate" do
    create(:vendor_rating, vendor: vendor, maintenance_request: maintenance_request, tenant: tenant, stars: 3)

    post rate_vendor_api_maintenance_request_path(maintenance_request),
      params: { stars: 5 },
      headers: auth_headers(tenant)

    expect(response).to have_http_status(:ok)
    expect(VendorRating.count).to eq(1)
    expect(VendorRating.first.stars).to eq(5)
  end

  it "rejects invalid star values" do
    post rate_vendor_api_maintenance_request_path(maintenance_request),
      params: { stars: 6 },
      headers: auth_headers(tenant)

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "returns forbidden for non-tenant users" do
    manager = create(:user, :property_manager)
    post rate_vendor_api_maintenance_request_path(maintenance_request),
      params: { stars: 4 },
      headers: auth_headers(manager)

    expect(response).to have_http_status(:forbidden)
  end

  it "returns error when no vendor is assigned" do
    request_no_vendor = create(:maintenance_request, tenant: tenant)
    post rate_vendor_api_maintenance_request_path(request_no_vendor),
      params: { stars: 4 },
      headers: auth_headers(tenant)

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
