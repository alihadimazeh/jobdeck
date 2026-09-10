class Room < ApplicationRecord
  belongs_to :quote, inverse_of: :rooms

  validates :name,   presence: true
  validates :length, presence: true, numericality: { greater_than: 0 }
  validates :width,  presence: true, numericality: { greater_than: 0 }

  before_save :calculate_area

  private

  def calculate_area
    self.area = length * width
  end
end
