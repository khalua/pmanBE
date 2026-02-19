require "rails_helper"

RSpec.describe VendorRating, type: :model do
  let(:vendor) { create(:vendor) }
  let(:tenant) { create(:user) }
  let(:maintenance_request) { create(:maintenance_request, tenant: tenant) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:stars) }
    it { is_expected.to validate_inclusion_of(:stars).in_range(1..5) }

    it "enforces one rating per vendor per request" do
      create(:vendor_rating, vendor: vendor, maintenance_request: maintenance_request, tenant: tenant, stars: 4)
      duplicate = build(:vendor_rating, vendor: vendor, maintenance_request: maintenance_request, tenant: tenant, stars: 5)
      expect(duplicate).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:vendor) }
    it { is_expected.to belong_to(:maintenance_request) }
    it { is_expected.to belong_to(:tenant).class_name("User") }
  end
end
