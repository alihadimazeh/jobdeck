class Order < ApplicationRecord
  enum :status, { draft: 0, confirmed: 1, invoiced: 2, paid: 3, cancelled: 4 }, suffix: true

  belongs_to :job
  belongs_to :customer
  belongs_to :lead, optional: true

  has_many :line_items, dependent: :destroy, inverse_of: :order
  has_many :activity_notes, as: :notable, dependent: :destroy
  has_many :documents, as: :documentable, dependent: :destroy

  validates :status, presence: true

  accepts_nested_attributes_for :line_items, allow_destroy: true, reject_if: :all_blank

  # Split on purpose rather than one "outstanding" bucket: a draft isn't money anyone owes yet,
  # and lumping it in with invoices made the dashboard's "owed" number mean two things.
  # Not yet billed - still being put together or agreed, no invoice out.
  scope :to_bill, -> { where(status: [ :draft, :confirmed ]) }
  # Invoiced, waiting on the customer to pay.
  scope :awaiting_payment, -> { where(status: :invoiced) }

  # Whole days past due_date, or nil when it isn't due yet (or has no due date). Only an
  # invoiced order can be overdue - a draft's due_date is a plan, not a demand for payment.
  def days_overdue
    return unless invoiced_status? && due_date
    days = (Date.current - due_date).to_i
    days if days.positive?
  end

  before_validation :assign_customer_from_job
  before_create     :assign_order_number
  before_save       :recalculate_totals

  private

  def assign_customer_from_job
    self.customer_id ||= job&.customer_id
  end

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
