require "rails_helper"

RSpec.describe Unit, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:identifier) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:property) }
    it { is_expected.to have_one(:tenant).class_name("User").dependent(:nullify) }
  end

  it "nullifies tenant unit_id on destroy" do
    unit = create(:unit)
    tenant = create(:user, unit: unit)

    unit.destroy!
    expect(tenant.reload.unit_id).to be_nil
  end
end
