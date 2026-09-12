FactoryBot.define do
  factory :lead do
    customer
    sequence(:title) { |n| "Lead #{n}" }
    status { :new }
  end
end
