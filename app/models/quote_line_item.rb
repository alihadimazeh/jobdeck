class QuoteLineItem < ApplicationRecord
  include BillableLineItem

  belongs_to :quote, inverse_of: :quote_line_items
end
