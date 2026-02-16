class DeviceToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: { scope: :user_id }
  validates :platform, presence: true, inclusion: { in: %w[ios android] }
end
