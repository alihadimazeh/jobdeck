FactoryBot.define do
  factory :room do
    quote
    sequence(:name) { |n| "Room #{n}" }
    length { 10 }
    width  { 12 }
  end
end
