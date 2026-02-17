class PhoneVerification < ApplicationRecord
  belongs_to :user

  validates :phone_number, presence: true
  validates :code, presence: true
  validates :expires_at, presence: true

  before_validation :generate_code, on: :create
  before_validation :set_expiry, on: :create

  def expired?
    expires_at < Time.current
  end

  def verified?
    verified_at.present?
  end

  private

  def generate_code
    self.code ||= format("%06d", SecureRandom.random_number(1_000_000))
  end

  def set_expiry
    self.expires_at ||= 10.minutes.from_now
  end
end
