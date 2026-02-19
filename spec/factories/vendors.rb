FactoryBot.define do
  factory :vendor do
    name { Faker::Company.name }
    cell_phone { Faker::PhoneNumber.cell_phone }
    phone_number { Faker::PhoneNumber.phone_number }
    vendor_type { :plumbing }
    is_available { true }
    address { Faker::Address.full_address }
    contact_name { Faker::Name.name }
    email { Faker::Internet.email }
    specialties { [ "pipes", "drains" ] }
  end
end
