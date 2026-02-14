class User < ApplicationRecord
  has_secure_password

  has_many :maintenance_requests, foreign_key: :tenant_id, dependent: :destroy

  enum :role, { tenant: 0, property_manager: 1 }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
end
