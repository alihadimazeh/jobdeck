class Quote < ApplicationRecord
  enum :status, { draft: 0, sent: 1, accepted: 2, rejected: 3, expired: 4 }, suffix: true

  belongs_to :lead
  belongs_to :customer

  has_many :rooms,            dependent: :destroy, inverse_of: :quote
  has_many :quote_line_items, dependent: :destroy, inverse_of: :quote

  accepts_nested_attributes_for :rooms,            allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :quote_line_items, allow_destroy: true, reject_if: :all_blank

  validates :status, presence: true
  validate  :only_one_accepted_quote_per_lead, if: :accepted_status?

  before_validation :assign_customer_from_lead
  before_create     :assign_quote_number
  before_save       :recalculate_totals

  after_save { self.lead.convert_to_job!(self) if saved_change_to_status? to: "accepted" }

  def total_area
    rooms.sum { |room| room.area || 0 }
  end

  private

  def only_one_accepted_quote_per_lead
    if lead.quotes.where(status: :accepted).where.not(id: id).exists?
      errors.add(:status, "already has an accepted quote for this lead")
    end
  end

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
