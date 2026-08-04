class Quote < ApplicationRecord
  enum :status, { draft: 0, sent: 1, accepted: 2, rejected: 3, expired: 4 }, suffix: true

  belongs_to :lead
  belongs_to :customer

  has_many :rooms,            dependent: :destroy
  has_many :quote_line_items, dependent: :destroy

  accepts_nested_attributes_for :rooms,            allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :quote_line_items, allow_destroy: true, reject_if: :all_blank

  validates :status, presence: true

  before_create :assign_quote_number
  before_save   :recalculate_totals

  def total_area
    rooms.sum { |room| room.area || 0 }
  end

  private

  def assign_quote_number
    year = Date.current.year
    last = Quote.where("quote_number LIKE ?", "QUO-#{year}-%").maximum(:quote_number)
    seq  = last ? last.split("-").last.to_i + 1 : 1
    self.quote_number = "QUO-#{year}-#{seq.to_s.rjust(4, '0')}"
  end

  def recalculate_totals
    items = quote_line_items.reject(&:marked_for_destruction?)
    self.subtotal = items.sum { |li| (li.quantity || 0) * (li.unit_price || 0) }
    self.total    = subtotal + (subtotal * (tax_rate || 0))
  end
end
