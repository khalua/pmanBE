FactoryBot.define do
  factory :property do
    address { Faker::Address.full_address }
    name { Faker::Company.name }
    property_type { :building }
    association :property_manager, factory: [ :user, :property_manager ]
  end
end
