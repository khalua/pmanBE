FactoryBot.define do
  factory :maintenance_request do
    issue_type { "plumbing" }
    location { "Unit 101 - Kitchen" }
    severity { :moderate }
    status { :submitted }
    conversation_summary { "Leaking faucet in kitchen" }
    allows_direct_contact { true }
    association :tenant, factory: :user
  end
end
