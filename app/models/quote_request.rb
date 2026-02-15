class QuoteRequest < ApplicationRecord
  belongs_to :maintenance_request
  belongs_to :vendor

  enum :status, { pending: 0, sent: 1, quoted: 2, declined: 3 }

  validates :vendor_id, uniqueness: { scope: :maintenance_request_id }

  before_create :set_token

  private

  def set_token
    self.token ||= SecureRandom.uuid
  end
end
