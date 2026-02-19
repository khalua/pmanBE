class PropertyManagerVendor < ApplicationRecord
  belongs_to :user
  belongs_to :vendor

  validates :vendor_id, uniqueness: { scope: :user_id }

  scope :active, -> { where(is_active: true) }
end
