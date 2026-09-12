FactoryBot.define do
  factory :quote do
    lead
    customer { lead.customer }
    status   { :draft }
    tax_rate { 0 }

    trait :accepted do
      status { :accepted }
    end

    trait :with_line_items do
      transient do
        line_items_count { 1 }
      end

      after(:create) do |quote, evaluator|
        create_list(:quote_line_item, evaluator.line_items_count, quote: quote)
      end
    end
  end
end
