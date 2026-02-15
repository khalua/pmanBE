class Property < ApplicationRecord
  belongs_to :property_manager, class_name: "User"
  has_many :units, dependent: :destroy

  enum :property_type, { house: 0, building: 1 }

  validates :address, presence: true
  validates :property_type, presence: true
end
