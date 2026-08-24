class LineItem < ApplicationRecord
  enum :item_type, { material: 0, labor: 1, other: 2 }, suffix: true

  belongs_to :order

  validates :item_type,   presence: true
  validates :description, presence: true
  validates :quantity,    numericality: { greater_than: 0 }
  validates :unit_price,  numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total

  private

  def calculate_total
    self.total = (quantity || 0) * (unit_price || 0)
  end
end
