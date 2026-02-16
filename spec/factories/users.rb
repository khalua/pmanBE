FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }
    phone { Faker::PhoneNumber.phone_number }
    mobile_phone { Faker::PhoneNumber.cell_phone }
    address { Faker::Address.full_address }
    role { :tenant }

    trait :property_manager do
      role { :property_manager }
    end

    trait :super_admin do
      role { :super_admin }
    end
  end
end
