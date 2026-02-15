FactoryBot.define do
  factory :property_manager_vendor do
    association :user, factory: :user, role: :property_manager
    vendor
  end
end
