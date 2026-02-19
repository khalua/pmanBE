class ManagerInvitation < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :claimed_by, class_name: "User", optional: true

  validates :code, presence: true, uniqueness: true
  validates :manager_name, presence: true
  validates :manager_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :expires_at, presence: true

  before_validation :generate_code, on: :create
  before_validation :set_expiry, on: :create

  scope :available, -> { where(active: true, claimed_by_id: nil).where("expires_at > ?", Time.current) }

  def claimed?
    claimed_by_id.present?
  end

  def expired?
    expires_at < Time.current
  end

  def available?
    active? && !claimed? && !expired?
  end

  private

  def generate_code
    self.code ||= loop do
      candidate = SecureRandom.alphanumeric(6).upcase
      break candidate unless ManagerInvitation.exists?(code: candidate)
    end
  end

  def set_expiry
    self.expires_at ||= 30.days.from_now
  end
end
