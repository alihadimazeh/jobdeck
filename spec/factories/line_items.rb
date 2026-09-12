FactoryBot.define do
  factory :line_item do
    order
    item_type   { :material }
    description { "Tile" }
    quantity    { 1 }
    unit        { "sqft" }
    unit_price  { 5 }
  end
end
