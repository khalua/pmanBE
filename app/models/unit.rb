class Unit < ApplicationRecord
  belongs_to :property
  has_one :tenant, class_name: "User", dependent: :nullify

  validates :identifier, presence: true
end
