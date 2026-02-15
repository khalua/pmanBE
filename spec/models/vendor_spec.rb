require "rails_helper"

RSpec.describe Vendor, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:phone_number) }
    it { is_expected.to validate_presence_of(:vendor_type) }
  end

  describe "associations" do
    it { is_expected.to have_many(:quotes).dependent(:destroy) }
    it { is_expected.to have_many(:assigned_requests).class_name("MaintenanceRequest").with_foreign_key(:assigned_vendor_id) }
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:vendor_type)
        .with_values(plumbing: 0, appliance: 1, electrical: 2, hvac: 3, general: 4, roofing: 5, flooring: 6, pest_control: 7)
    end
  end
end
