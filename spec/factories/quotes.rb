FactoryBot.define do
  factory :quote do
    estimated_cost { 250.00 }
    work_description { "Replace leaking faucet and check pipes" }
    estimated_arrival_time { 2.days.from_now }
    association :vendor
    association :maintenance_request
  end
end
