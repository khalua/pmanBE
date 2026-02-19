class VendorRating < ApplicationRecord
  belongs_to :vendor
  belongs_to :maintenance_request
  belongs_to :tenant, class_name: "User"

  validates :stars, presence: true, inclusion: { in: 1..5 }
  validates :maintenance_request_id, uniqueness: { scope: :vendor_id }
end
