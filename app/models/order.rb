class Order < ApplicationRecord
  enum :status, { draft: 0, confirmed: 1, invoiced: 2, paid: 3, cancelled: 4 }, suffix: true

  belongs_to :job
  belongs_to :customer
  belongs_to :lead, optional: true

  has_many :line_items, dependent: :destroy, inverse_of: :order

  validates :status, presence: true

  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank

  before_create :assign_order_number
  before_save :recalculate_totals

  private

  def assign_order_number
    year = Date.current.year
    last = Order.where("order_number LIKE ?", "ORD-#{year}-%").maximum(:order_number)
    seq  = last ? last.split("-").last.to_i + 1 : 1
    self.order_number = "ORD-#{year}-#{seq.to_s.rjust(4, '0')}"
  end

  def recalculate_totals
    items = line_items.reject(&:marked_for_destruction?)
    self.subtotal = items.sum { |li| (li.quantity || 0) * (li.unit_price || 0) }
    self.total    = subtotal + (subtotal * (tax_rate || 0))
  end
end
