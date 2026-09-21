class Lead < ApplicationRecord
  enum :status, { new: 0, contacted: 1, quoted: 2, converted: 3, lost: 4 }, suffix: true
  enum :job_type, { tile: 0, flooring: 1, materials: 2, kitchen: 3, mixed: 4 }, suffix: true
  enum :source, { walk_in: 0, phone: 1, referral: 2, website: 3, other: 4 }, suffix: true

  validates :title, presence: true

  belongs_to :customer
  has_many :orders, dependent: :restrict_with_error
  has_one  :job,    dependent: :nullify
  has_many :quotes, dependent: :destroy
  has_many :activity_notes, as: :notable, dependent: :destroy

  # Leads still in the pipeline (not converted or lost) with a follow-up date today or
  # earlier. NULL follow_up_date rows are excluded automatically - `<= value` is never
  # true against NULL in SQL, no explicit `.where.not(follow_up_date: nil)` needed.
  scope :needs_follow_up, -> { where(follow_up_date: ..Date.current).where.not(status: [ :converted, :lost ]) }

  def convert_to_job!(quote)
    raise "This lead has already been converted to a job" if job.present?

    transaction do
      job = create_job!(
        attributes.slice("title", "description", "job_type", "assigned_to", "estimated_value")
          .merge(customer.attributes.slice("address_line_1", "address_line_2", "city", "province", "postal_code"))
          .merge(customer: customer)
      )

      job.orders.create!(
        customer: customer,
        lead: self,
        line_items_attributes: quote.quote_line_items.map { |item|
          item.attributes.slice("item_type", "description", "quantity", "unit", "unit_price")
        }
      )

      update!(status: :converted)
    end
  end
end
