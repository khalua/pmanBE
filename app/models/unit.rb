class Unit < ApplicationRecord
  belongs_to :property
  has_many :tenants, class_name: "User", dependent: :nullify
  has_many :tenant_invitations, dependent: :destroy

  validates :identifier, presence: true

  def current_tenants
    tenants.where("move_out_date IS NULL OR move_out_date >= ?", Date.current)
  end

  def past_tenants
    tenants.where("move_out_date IS NOT NULL AND move_out_date < ?", Date.current)
  end

  def vacant?
    current_tenants.none?
  end
end
