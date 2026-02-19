FactoryBot.define do
  factory :manager_invitation do
    association :created_by, factory: [ :user, :super_admin ]
    manager_name { Faker::Name.name }
    manager_email { Faker::Internet.unique.email }
  end
end
