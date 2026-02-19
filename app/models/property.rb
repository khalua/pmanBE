class Property < ApplicationRecord
  belongs_to :property_manager, class_name: "User"
  has_many :units, dependent: :destroy

  enum :property_type, { house: 0, building: 1 }

  validates :address, presence: true
  validates :property_type, presence: true

  after_create :create_default_unit_for_house

  private

  def create_default_unit_for_house
    units.create!(identifier: "Main Unit") if house?
  end
end
