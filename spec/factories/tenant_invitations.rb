FactoryBot.define do
  factory :tenant_invitation do
    unit
    association :created_by, factory: [ :user, :property_manager ]
    tenant_name { Faker::Name.name }
    tenant_email { Faker::Internet.unique.email }
  end
end
