class MaintenanceRequestNote < ApplicationRecord
  belongs_to :maintenance_request
  belongs_to :user

  validates :content, presence: true
end
