class Vendor < ApplicationRecord
  has_many :quotes, dependent: :destroy
  has_many :assigned_requests, class_name: "MaintenanceRequest", foreign_key: :assigned_vendor_id

  enum :vendor_type, {
    plumbing: 0,
    appliance: 1,
    electrical: 2,
    hvac: 3,
    general: 4,
    roofing: 5,
    flooring: 6,
    pest_control: 7
  }

  validates :name, presence: true
  validates :phone_number, presence: true
  validates :vendor_type, presence: true

  serialize :specialties, coder: JSON
end
