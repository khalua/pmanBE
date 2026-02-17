class User < ApplicationRecord
  has_secure_password

  belongs_to :unit, optional: true
  has_many :maintenance_requests, foreign_key: :tenant_id, dependent: :destroy
  has_many :maintenance_request_notes, dependent: :destroy
  has_many :properties, foreign_key: :property_manager_id, dependent: :destroy
  has_many :device_tokens, dependent: :destroy
  has_many :property_manager_vendors, dependent: :destroy
  has_many :vendors, through: :property_manager_vendors
  has_many :tenant_invitations, foreign_key: :created_by_id, dependent: :destroy
  has_many :phone_verifications, dependent: :destroy

  enum :role, { tenant: 0, property_manager: 1, super_admin: 2 }

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :mobile_phone, presence: true, if: :tenant?

  def gmail_account?
    email&.downcase&.end_with?("@gmail.com")
  end
end
