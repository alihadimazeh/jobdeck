FactoryBot.define do
  factory :customer do
    sequence(:first_name) { |n| "Customer#{n}" }
    last_name { "Test" }
    phone     { "555-0100" }
  end
end
