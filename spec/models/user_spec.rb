require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to have_secure_password }

    it "rejects invalid email formats" do
      user = build(:user, email: "not-an-email")
      expect(user).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:maintenance_requests).with_foreign_key(:tenant_id).dependent(:destroy) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(tenant: 0, property_manager: 1) }
  end
end
