class Lead < ApplicationRecord
  enum :status, { new: 0, contacted: 1, quoted: 2, converted: 3, lost: 4 }, suffix: true
  enum :job_type, { tile: 0, flooring: 1, materials: 2, kitchen: 3, mixed: 4 }, suffix: true
  enum :source, { walk_in: 0, referral: 1, phone: 2, website: 3, other: 4 }

  belongs_to :customer
  has_one  :job,    dependent: :nullify
  has_many :quotes, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  def convert_to_job!(quote)
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
