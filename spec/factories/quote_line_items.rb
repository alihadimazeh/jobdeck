FactoryBot.define do
  factory :quote_line_item do
    quote
    item_type   { :material }
    description { "Tile" }
    quantity    { 1 }
    unit        { "sqft" }
    unit_price  { 5 }
  end
end
