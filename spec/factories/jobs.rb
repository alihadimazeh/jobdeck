FactoryBot.define do
  factory :job do
    customer
    sequence(:title) { |n| "Job #{n}" }
    status { :active }

    trait :from_lead do
      lead
      customer { lead.customer }
    end
  end
end
