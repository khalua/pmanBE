require "rails_helper"

RSpec.describe PropertyManagerVendor, type: :model do
  it "belongs to user and vendor" do
    pmv = create(:property_manager_vendor)
    expect(pmv.user).to be_present
    expect(pmv.vendor).to be_present
  end

  it "enforces uniqueness of vendor per user" do
    pmv = create(:property_manager_vendor)
    duplicate = build(:property_manager_vendor, user: pmv.user, vendor: pmv.vendor)
    expect(duplicate).not_to be_valid
  end
end
