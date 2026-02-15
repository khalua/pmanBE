FactoryBot.define do
  factory :unit do
    property
    identifier { "Unit #{Faker::Alphanumeric.alphanumeric(number: 3).upcase}" }
    floor { rand(1..10) }
  end
end
