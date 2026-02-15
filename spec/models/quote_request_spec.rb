require "rails_helper"

RSpec.describe QuoteRequest, type: :model do
  it "belongs to maintenance_request and vendor" do
    qr = create(:quote_request)
    expect(qr.maintenance_request).to be_present
    expect(qr.vendor).to be_present
  end

  it "enforces uniqueness of vendor per maintenance_request" do
    qr = create(:quote_request)
    duplicate = build(:quote_request, maintenance_request: qr.maintenance_request, vendor: qr.vendor)
    expect(duplicate).not_to be_valid
  end

  it "defaults to pending status" do
    qr = create(:quote_request)
    expect(qr).to be_pending
  end

  it "generates a token on create" do
    qr = create(:quote_request)
    expect(qr.token).to be_present
    expect(qr.token).to match(/\A[0-9a-f-]{36}\z/)
  end

  it "does not overwrite a pre-set token" do
    qr = create(:quote_request, token: "custom-token")
    expect(qr.token).to eq("custom-token")
  end
end
