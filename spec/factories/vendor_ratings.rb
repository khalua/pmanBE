FactoryBot.define do
  factory :vendor_rating do
    vendor
    maintenance_request
    association :tenant, factory: :user
    stars { 4 }
    comment { "Good work." }
  end
end
