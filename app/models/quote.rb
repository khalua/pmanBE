class Quote < ApplicationRecord
  belongs_to :vendor, optional: true
  belongs_to :maintenance_request

  validates :estimated_cost, presence: true, numericality: { greater_than: 0 }
  validates :work_description, presence: true
end
