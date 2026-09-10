class LineItem < ApplicationRecord
  include BillableLineItem

  belongs_to :order, inverse_of: :line_items
end
