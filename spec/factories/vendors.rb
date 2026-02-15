FactoryBot.define do
  factory :vendor do
    name { Faker::Company.name }
    phone_number { Faker::PhoneNumber.phone_number }
    vendor_type { :plumbing }
    rating { 4.5 }
    is_available { true }
    location { Faker::Address.city }
    specialties { ["pipes", "drains"] }
  end
end
