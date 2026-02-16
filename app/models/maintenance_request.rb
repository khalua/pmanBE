class MaintenanceRequest < ApplicationRecord
  belongs_to :tenant, class_name: "User"
  belongs_to :assigned_vendor, class_name: "Vendor", optional: true
  has_many :notes, class_name: "MaintenanceRequestNote", dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :quote_requests, dependent: :destroy
  has_many_attached :images

  enum :severity, { minor: 0, moderate: 1, urgent: 2, emergency: 3 }
  enum :status, {
    submitted: 0,
    vendor_quote_requested: 1,
    quote_received: 2,
    quote_accepted: 3,
    quote_rejected: 4,
    in_progress: 5,
    completed: 6
  }

  validates :issue_type, presence: true
  validates :location, presence: true
end
