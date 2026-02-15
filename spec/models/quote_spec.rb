require "rails_helper"

RSpec.describe Quote, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:estimated_cost) }
    it { is_expected.to validate_numericality_of(:estimated_cost).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:work_description) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:vendor).optional }
    it { is_expected.to belong_to(:maintenance_request) }
  end
end
