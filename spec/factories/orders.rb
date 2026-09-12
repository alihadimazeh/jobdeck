FactoryBot.define do
  factory :order do
    job
    customer { job.customer }
    status   { :draft }
    tax_rate { 0 }

    trait :with_lead do
      lead { job.lead }
    end
  end
end
