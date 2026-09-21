FactoryBot.define do
  factory :activity_note do
    notable factory: :lead
    body { "Called the customer, they're happy with progress." }
    author { "Jane PM" }
    pinned { false }
  end
end
