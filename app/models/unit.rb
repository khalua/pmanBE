class Unit < ApplicationRecord
  belongs_to :property
  has_many :tenants, class_name: "User", dependent: :nullify
  has_many :tenant_invitations, dependent: :destroy

  validates :identifier, presence: true
end
