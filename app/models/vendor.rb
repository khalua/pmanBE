class Vendor < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: :owner_user_id, optional: true
  has_many :quotes, dependent: :destroy
  has_many :assigned_requests, class_name: "MaintenanceRequest", foreign_key: :assigned_vendor_id
  has_many :property_manager_vendors, dependent: :destroy
  has_many :property_managers, through: :property_manager_vendors, source: :user
  has_many :quote_requests, dependent: :destroy
  has_many :vendor_ratings, dependent: :destroy

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
  validates :cell_phone, presence: true
  validates :vendor_type, presence: true

  serialize :specialties, coder: JSON

  def average_rating
    vendor_ratings.average(:stars)&.round(1)
  end

  def quotes_received_count
    quotes.count
  end

  def requests_fulfilled_count
    assigned_requests.where(status: :completed).count
  end
end
