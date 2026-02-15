FactoryBot.define do
  factory :quote_request do
    maintenance_request
    vendor
    status { :pending }
  end
end
