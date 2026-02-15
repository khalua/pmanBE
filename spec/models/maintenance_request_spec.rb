require "rails_helper"

RSpec.describe MaintenanceRequest, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:issue_type) }
    it { is_expected.to validate_presence_of(:location) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:tenant).class_name("User") }
    it { is_expected.to belong_to(:assigned_vendor).class_name("Vendor").optional }
    it { is_expected.to have_many(:quotes).dependent(:destroy) }
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:severity)
        .with_values(minor: 0, moderate: 1, urgent: 2, emergency: 3)
    end

    it do
      is_expected.to define_enum_for(:status)
        .with_values(
          submitted: 0, vendor_quote_requested: 1, quote_received: 2,
          quote_accepted: 3, quote_rejected: 4, in_progress: 5, completed: 6
        )
    end
  end
end
