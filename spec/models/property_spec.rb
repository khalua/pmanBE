require "rails_helper"

RSpec.describe Property, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:property_type) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:property_manager).class_name("User") }
    it { is_expected.to have_many(:units).dependent(:destroy) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:property_type).with_values(house: 0, building: 1) }
  end
end
